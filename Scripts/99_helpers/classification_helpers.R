load_features_and_meta = function(csv_path, emotions = c("ANG", "DIS", "FER", "HAP", "NEU", "SAD")){
  try_again = TRUE
  i = 0
  while (try_again){
    i = i + 1
    if (i > 10){
      try_again = FALSE
    }
    tryCatch({
      features = read.csv(csv_path)
      try_again = FALSE
    },
    error = function(e){}
    )
  }
  
  meta_df = as.data.frame(stringr::str_split_fixed(features$filename, "_", 5)[, 1:5])
  names(meta_df) = c("speaker", "emotion", "sentence", "intensity", "rep")
  
  # Remove filename
  meta_df$filename = features$filename
  features = features[-1]
  
  # Use limited set of emotions
  row_idx = meta_df$emotion %in% emotions
  features = features[row_idx, ]
  meta_df = meta_df[row_idx, ]
  meta_df$emotion = droplevels(meta_df$emotion)
  
  return(list(
    features = features,
    meta_df = meta_df
  ))
}

get_col_names = function(feature_set, features){
  if (feature_set == "both") {
    col_names = names(features)
  } else if (feature_set == "new") {
    col_names = names(features)[89:146]
  } else if (feature_set == "baseline") {
    col_names = names(features)[1:88]
  } else if (feature_set == "eGeMAPS_F0"){
    col_names = names(features)[1:10]
  } else if (feature_set == "eGeMAPS_freq"){
    col_names = names(features)[1:30]
  } else if (feature_set == "new_dynamic"){
    col_names = names(features)[89:146]
    col_names = col_names[!col_names %in% c('skewness', 'kurtosis', 'entropy')]
  }
  else{
    stop('this may not happen')
  }
  
  # remove inreliable measurements
  #col_names = col_names[!col_names %in% c("peak_frequency", "peak_amplitude", "st_compression_rate", "st_peak_frequency", "st_peak_amplitude", "smallest harmonic", "relative harmonic", "stylized_INTSINT_count", "min_max_slope")]
  #col_names = col_names[!grepl('reference', col_names)]
  
  # Remove not true dynamic features
  col_names = col_names[!col_names %in% c('skewness', 'kurtosis', 'entropy', "max_freq", "num_ICCs", "mean_tc", "sd_tc" )]
  
  # Remove compression
  col_names = col_names[!grepl('compression', col_names)]
  return(col_names)
}

eval_str = function(str){
  return(eval(parse(text = str)))
}

filter_by = function(features, meta_df, filter_str){
  #library(dplyr)
  #filename = features$filename
  temp = cbind(features, meta_df)
  temp = eval(parse(text = paste0("filter(temp, ", filter_str, ")")))
  features = temp[1:ncol(features)]
  meta_df = temp[(ncol(features) + 1):ncol(temp)]
  return(list(
    features = features,
    meta_df = meta_df
  ))
}


classification = function(csv_path, idx, feature_set, by, column_info = list()){
  csv_path = toString(csv_path)
  idx = strsplit(toString(idx),",")[[1]]
  feature_set = toString(feature_set)
  by = toString(by)
  if (!by %in% c("speaker", "sentence")) {
    stop()
  }
  
  rtrn = load_features_and_meta(csv_path)
  features = rtrn$features
  meta_df = rtrn$meta_df
  if ("filter_str" %in% names(column_info)) {
    rtrn = filter_by(features, meta_df, column_info$filter_str)
    features = rtrn$features
    meta_df = rtrn$meta_df
  }
  
  col_names = get_col_names(feature_set, features)
  
  labels = meta_df$emotion
  test_rows = meta_df[[by]] %in% idx
  test_features = features[test_rows, col_names]
  training_features = features[!test_rows, col_names]
  
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
  sensitivity_mean = mean(sensitivity, na.rm = T)
  
  specificity = class_results$byClass[,2]
  names(specificity) = paste0("spec_", names(accuracy))
  specificity_mean = mean(specificity, na.rm = T)
  
  precision = class_results$byClass[,3]
  names(precision) = paste0("prec_", names(accuracy))
  precision_mean = mean(precision,  na.rm = T)
  
  names(accuracy) = paste0("acc_", names(accuracy))
  
  new_row = data.frame(
    acc_mean = accuracy_mean,
    sense_mean = sensitivity_mean,
    spec_mean = specificity_mean,
    precision_mean = precision_mean,
    feature_set = feature_set
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

to_str = function(...){
  args = list(...)
  m = ""
  for (arg in args){
    m = paste(m, toString(arg))
  }
  return(m)
}
