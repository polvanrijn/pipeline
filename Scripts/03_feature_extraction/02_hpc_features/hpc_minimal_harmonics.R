source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/hpc.R"))
setup_connection()

corpora = strsplit(Sys.getenv("CORPORA"), ",")[[1]]

minimal_harmonics = function(corpus){
  library(contouR)
  resamp_df = read.csv(paste0("~/Sentence_wise_compression/", corpus, "/naive_sentence_wise_resampled.csv"))
  #telegram_send_message(paste(corpus, "minimal harmonics starts"))
  return_df = compute_minimal_harmonics(resamp_df)
  #telegram_send_message(paste(corpus, "minimal harmonics ends"))
  return(return_df)
}
df = data.frame(corpus = corpora)
job = hpc_run(minimal_harmonics, list(df = df))
results = slurm_result(job)

count = 0
for (corpus in corpora) {
  count = count + 1
  files = list.files(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/02_estimated/"))
  files = files[grep('.csv', files)]
  files = sort(files)

  feature_df = results[[count]]
  if (head(files, 1) != paste0(head(sort(as.character(feature_df$filename)), 1), ".csv")) {
    stop('This may not happen')
  }
  write.csv(feature_df, paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Features/minimal_harmonics.csv"), row.names = F)
}
