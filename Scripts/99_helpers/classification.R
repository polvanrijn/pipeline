start_idx = 89

slice = function(input, by=2){
  starts = seq(1,length(input),by)
  tt = lapply(starts, function(y) input[y:(y+(by-1))])
  plyr::llply(tt, function(x) x[!is.na(x)])
}

get_meta = function(filenames){
  meta_df = as.data.frame(stringr::str_split_fixed(filenames, "_", 5)[, 1:5])
  names(meta_df) = c("speaker", "emotion", "sentence", "intensity", "rep")
  return(meta_df)
}

create_cross_fold_template = function(
  corpus, 
  cross_validation_by = "sentence", 
  num_folds = 6, seed = 12, filter_str = NULL, 
  feature_sets = c('both', 'baseline'),
  rename_headers = c("idx", "part", "by", "csv", "corp", "feat")
){
  if (cross_validation_by %in% c("sentence", "speaker")){
    if (cross_validation_by == "sentence"){
      col_idx = 3
    } else {
      col_idx = 1
    }
  } else {
    stop()
  }
  
  if (length(feature_sets) < 1){
    stop('Need at least one feature set')
  }
  
  features = read.csv(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Features/combined_features.csv"))
  meta_df = get_meta(features$filename)
  
  if (!is.null(filter_str)){
    library(dplyr)
    temp = cbind(features, meta_df)
    temp = eval(parse(text = paste0("filter(temp, ", filter_str, ")")))
    features = temp[1:ncol(features)]
    meta_df = temp[(ncol(features) + 1):ncol(temp)]
  }
  
  to_randomize = as.character(unique(meta_df[, col_idx]))
  items_per_partition = ceiling(length(to_randomize)/num_folds)
  set.seed(seed)
  test_sets = slice(sample(to_randomize), items_per_partition)
  cross_fold_template = do.call("rbind", lapply(test_sets, function(x){
    return(data.frame(idx = paste(x, collapse = ",")))
  }))
  cross_fold_template$partition = 1:nrow(cross_fold_template)
  cross_fold_template$by = cross_validation_by
  cross_fold_template$csv_path = paste0("~/features/", corpus, "/combined_features.csv")
  cross_fold_template$corpus = corpus
  
  rtnr_df = NULL
  
  for (fs in feature_sets){
    tmp_df = cross_fold_template
    tmp_df$feature_set = fs
    rtnr_df = rbind(rtnr_df, tmp_df)
  }
  
  if (length(names(rtnr_df)) != length(rename_headers)){
    stop("You must specify names for each column!")
  }
  
  names(rtnr_df) = rename_headers
  
  return(rtnr_df)
}

get_lower_col_mat = function(df){
  cor_df = cor(na.omit(df))
  cor_df[upper.tri(cor_df, diag = TRUE)] = 0
  return(cor_df)
}

get_correlated_idx = function(cor_df){
  idxs = which(abs(cor_df) > 0.7, arr.ind = TRUE)
  sort(unique(c(idxs[,1], idxs[,2]))) + start_idx - 1
}

create_random_forest_template = function(corpus, i = 10){
  features = read.csv(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Features/combined_features.csv"))
  features = features[-1]
  
  end_idx = ncol(features)
  new_ft_idxs = start_idx:end_idx
  new_features = features[start_idx:end_idx]
  
  cor_df = get_lower_col_mat(new_features)
  idxs_to_remove = get_correlated_idx(cor_df)
  
  no_cor_idxs = new_ft_idxs[!new_ft_idxs %in% idxs_to_remove]
  no_cor_feat = features[, no_cor_idxs]
  
  # Let's check
  if (any(abs(get_lower_col_mat(no_cor_feat)) > 0.7)){
    stop('This may not happen! Some features have a too high correlation')
  }
  #selected_features = names(features)[idxs_to_remove]
  idxs_to_remove = idxs_to_remove[!idxs_to_remove %in% c(which(names(features) %in% c("peak_frequency", "peak_amplitude", "st_compression_rate", "st_peak_frequency", "st_peak_amplitude", "smallest harmonic", "relative harmonic", "stylized_INTSINT_count", "min_max_slope")), grep('reference', names(features)))]
  no_cor_idxs = paste(no_cor_idxs, collapse = ",")
  return(
    data.frame(
      corpus = corpus,
      idx = rep(idxs_to_remove, i),
      no_cor_idxs = no_cor_idxs,
      repetition = unlist(lapply(1:i, function(x) rep(x, length(no_cor_idxs))))
    )
  )
}

get_results = function(job){
  remote_dir = paste0('~/hpcR/_rslurm_', job$jobname, '/')
  result_files = hpc_ls(remote_dir)
  result_files = result_files[grep("results_", result_files)]
  # Download the results
  results = list()
  for (rf in result_files){
    hpc_copy_from(paste0(remote_dir, rf), tempdir())
    results = do.call(c, list(results, readRDS(paste0(tempdir(), "/", rf))))
  }
  return(results)
}



get_result_as_df = function(job){
  remote_dir = paste0('~/hpcR/_rslurm_', job$jobname, '/')
  result_files = hpc_ls(remote_dir)
  result_files = result_files[grep("results_", result_files)]
  # Download the results
  results = NULL
  for (rf in result_files){
    hpc_copy_from(paste0(remote_dir, rf), tempdir())
    res = readRDS(paste0(tempdir(), "/", rf))
    for (r in res){
      if (typeof(r) == "list"){
        results = rbind(results, r)
      } else {
        warning(r)
      }
    }
  }
  return(results)
}




create_rows = function(df, col_name, keep_cols = c("partition", "corpus", "feature_set")){
  vals = df[[col_name]]
  data = df[keep_cols]
  data$score = vals
  data$emotion = col_name
  data$emotion = stringr::str_remove(data$emotion, "sense_")
  return(data)
}

get_sense_cols = function(df){
  return(names(df)[grep("sense", names(df))[-1]])
}

wide_to_long = function(df){
  double_check = NULL
  for (col_name in get_sense_cols(df)){
    double_check = rbind(double_check, create_rows(df, col_name))
  }
  return(double_check)
}

run_t_test = function(df, metric_name, filter_by, f1, f2){
  if(!all(c(metric_name, filter_by) %in% names(df))){
    stop(paste("Dataframe must contain columns", filter_by, metric_name))
  }
  if (!all(c(f1, f2) %in% df[[filter_by]])){
    stop(paste("Both filters -", f1, f2, "- need to occur in column", filter_by))
  }
  vec1 = df[df[[filter_by]] == f1, metric_name]
  vec2 = df[df[[filter_by]] == f2, metric_name]
  return(t.test(vec1, vec2))
}

get_mean_diff = function(df, score_col = "sense_mean", group_by = "feature_set"){
  library(dplyr)
  filt = df %>% 
    group_by(.dots = "feature_set") %>% 
    summarize_at(.vars = score_col, .funs = mean)
  
  if (nrow(filt) != 2){
    stop("Needs two rows")
  }
  return(diff(filt[[score_col]])*100)
}

plot_results = function(df, x = 'feature_set', y = 'sense_mean', comparisons = list( c("both", "baseline")), title = NULL, plot_mean = TRUE){
  library(ggpubr)
  p = ggboxplot(df, x = x, y = y) +
    stat_compare_means(comparisons =  comparisons, label = "p.signif", method = "t.test") +
    scale_y_continuous(labels = scales::percent, limits = c(0, 1.1), breaks=seq(0,1,0.2))
  
  if (!is.null(title)){
    p = p + ggtitle(title)
  }
  

  
  return(p)
}


classification = function(features, meta_df, col_names, idx, by, column_info = list()){
  labels = meta_df$emotion
  test_rows = meta_df[[by]] %in% idx
  test_features = features[test_rows, col_names, drop = FALSE]
  training_features = features[!test_rows, col_names, drop = FALSE]
  
  test_labels = labels[test_rows]
  training_labels = labels[!test_rows]
  
  training = cbind(training_features, training_labels)
  training = training[!is.na(training_labels), ]
  training_labels = training_labels[!is.na(training_labels)]
  
  training = na.omit(training)
  
  test = cbind(test_features, test_labels)
  test = test[!is.na(test_labels), ]
  test_labels = test_labels[!is.na(test_labels)]
  test = na.omit(test)
  
  library(caret)
  require(kernlab)
  
  c = c(.1, .25, .5, .75)
  C = c(c[2:4]/10000, c/1000, c/100, c/10, c[1:2])
  
  set.seed(123)
  model = caret::train(
    training_labels ~.,
    data = training,
    method = "svmLinear",
    trControl = trainControl(method = 'repeatedcv', 10, 3),
    preProcess = c("center","scale"),
    tuneGrid = expand.grid(C = C)
  )
  
  predicted = predict(model, newdata = test)
  class_results = caret::confusionMatrix(predicted,test$test_labels)
  
  accuracy = diag(class_results$table)/colSums(class_results$table)
  accuracy_mean = sum(diag(class_results$table)) / sum(class_results$table)
  
  sensitivity = class_results$byClass[,1]
  names(sensitivity) = paste0("sense_", names(accuracy))
  sensitivity_mean = mean(sensitivity)
  
  specificity = class_results$byClass[,2]
  names(specificity) = paste0("spec_", names(accuracy))
  specificity_mean = mean(specificity)
  
  precision = class_results$byClass[,3]
  names(precision) = paste0("prec_", names(accuracy))
  precision_mean = mean(precision)
  
  names(accuracy) = paste0("acc_", names(accuracy))
  
  new_row = data.frame(
    acc_mean = accuracy_mean,
    sense_mean = sensitivity_mean,
    spec_mean = specificity_mean,
    precision_mean = precision_mean
  )
  
  if (length(column_info) > 0){
    for (i in 1:length(column_info)){
      key = names(column_info)[i]
      value = column_info[[i]]
      new_row[[key]] = toString(value)
    }
  }
  
  new_row = cbind(new_row, t(accuracy), t(sensitivity), t(specificity), t(precision))
  
  return(new_row)
}
