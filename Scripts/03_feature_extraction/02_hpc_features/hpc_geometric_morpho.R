source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/hpc.R"))
setup_connection()
corpora = strsplit(Sys.getenv("CORPORA"), ",")[[1]]

ggm = function(corpus){
  save_plots = function(pca_list, i = ""){
    if (i != ""){
      i = paste0("_", i)
    }
    plot_name = paste0(corpus, i, "_variance_plot.pdf")
    ggplot2::ggsave(plot_name, plot = pca_list$variance_plot)
    #telegram_upload_file(plot_name)
    
    plot_name = paste0(corpus, i, "_PCA_plot.pdf")
    ggplot2::ggsave(plot_name, plot = pca_list$pca_plot)
    #telegram_upload_file(plot_name)
  }
  library(contouR)
  corpus = toString(corpus)
  
  # Settings
  colors = c("#ce4d41", "#6ab79a", "#5e94cf", "#e7c540", "#bbbcbe", "#d27e35", "#88579f", "#CC62C4")
  labels = c("ANG", "DIS", "FER", "HAP", "NEU", "SAD", "SUR", "CAL")
  tier_path = paste0("~/Words/", corpus, "/")
  pt_path = paste0("~/PitchTiers/", corpus, "/")
  #telegram_send_message(paste(corpus, "test"))
  
  grouping_list = readRDS('~/word_idxs.RDS')[[corpus]]
  file_df = read.csv(paste0("~/file_df/", corpus, "/file_df.csv"))
  filenames = paste0(file_df$new_name, ".PitchTier")
  # Do superposition
  result = superposition_by_word(filenames, pt_path, tier_path, grouping_list)
  #superpositions = list(result)
  
  pca_list = pca_analysis(result, title_prefix = paste("For all words", corpus), prefix = "w0", center = TRUE,  scale = FALSE, colors = colors, labels = labels, return_plots = F)
  #save_plots(pca_list)
  
  features = pca_list$features
  
  method = "reference_angle"
  results = eigenshape_analysis(result, method)
  pca_list = pca_analysis(results, title_prefix =  "For all words", prefix = paste0(method, "_w0"), center = TRUE,  scale = FALSE, colors = colors, labels = labels, return_plots = F)
  #save_plots(pca_list, paste0("ref_angle_", i - 1))
  
  features = combine_features(features, pca_list$features)
  
  
  # group_df = t(as.data.frame(grouping_list))
  # for (i in 1:3) {
  #   grouping_sublist = as.list(as.numeric(group_df[,i]))
  #   tryCatch({
  #     result = superposition_by_word(filenames, pt_path, tier_path, grouping_sublist)
  #     superpositions[[i + 1]] = result
  #     pca_list = pca_analysis(result, title_prefix = paste("For word", i), prefix = paste0("w",i), center = TRUE,  scale = FALSE, colors = colors, labels = labels, return_plots = F)
  #     save_plots(pca_list, i)
  #     features = combine_features(features, pca_list$features)
  #   }, error = function(er){
  #     #telegram_send_message(paste0("**", toString(er), "**"))
  #   })
  # }
  
  #telegram_send_message(paste(corpus, "finished geometric morphometrics"))
  # method = "reference_angle"
  # for (i in 1:length(superpositions)){
  #   df = na.omit(superpositions[[i]])
  #   results = eigenshape_analysis(df, method)
  #   results$compression_rate = df$compression_rate
  #   if (i == 1) {
  #     title_prefix = "For all words"
  #   } else{
  #     title_prefix = paste("For word", i - 1)
  #   }
  #   pca_list = pca_analysis(results, title_prefix = title_prefix, prefix = paste0(method, "_w",i - 1), center = TRUE,  scale = FALSE, colors = colors, labels = labels, return_plots = F)
  #   save_plots(pca_list, paste0("ref_angle_", i - 1))
  # 
  #   features = combine_features(features, pca_list$features)
  # }
  
  #telegram_send_message(paste(corpus, "finished reference angle"))
  
  return(features)
}

df = data.frame(corpus = corpora)
job = hpc_run(ggm, list(df = df))

# for
results = slurm_result(job)
# Check if the order matches
count = 0
for (corpus in corpora){
  count = count + 1
  files = list.files(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/02_estimated/"))
  file = head(files[grep('.csv', files)], 1)
  feature_df = results[[count]]
  if (file != paste0(feature_df[1,1], ".csv")) {
    stop('This may not happen')
  }
  write.csv(feature_df, paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Features/morphometric.csv"), row.names = F)
}
disconnect()

