source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/hpc.R"))
setup_connection()

corpora = strsplit(Sys.getenv("CORPORA"), ",")[[1]]
compute_phrase = function(corpus){
  library(contouR)
  library(dplyr)

  corpus = toString(corpus)
  top_scores = read.csv(paste0("~/top_scores/", corpus, "/top_scores.csv"))
  place_1 = dplyr::filter(top_scores, placement == 1)
  place_1 = place_1[, c(1,2,4)]
  Fujisaki_path = paste0("~/Fujisaki/", corpus, "/")

  features = NULL
  for (r in 1:nrow(place_1)){
    features = rbind(features, compute_phrase_feature(place_1[r, "alpha"], place_1[r, "beta"], place_1[r, "file"], Fujisaki_path))
  }
  #telegram_send_message(paste(corpus, "finished"))
  return(features)
}
df = data.frame(corpus = corpora)
job = hpc_run(compute_phrase, list(df = df))

results = slurm_result(job)

count = 0
for (corpus in corpora) {
  count = count + 1
  files = sort(list.files(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/02_estimated/")))
  file = head(files[grep('.csv', files)], 1)
  feature_df = results[[count]]
  if (file != paste0(head(sort(feature_df$name), 1), ".csv")) {
    stop('This may not happen')
  }
  write.csv(feature_df, paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Features/phrase.csv"), row.names = F)
}

disconnect()

