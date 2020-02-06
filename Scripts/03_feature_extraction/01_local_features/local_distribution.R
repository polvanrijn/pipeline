path = paste0( Sys.getenv("PT_DIR"), "Corpora/")
library(contouR)

corpora = strsplit(Sys.getenv("CORPORA"), ",")[[1]]
for (corpus in corpora) {
  corpus_path = paste0(path, corpus, "/")
  feartures_path = paste0(corpus_path, "Features/")
  if (!dir.exists(feartures_path)) {
    dir.create(feartures_path)
  }
  pt_path = paste0(corpus_path, "PitchTiers/02_estimated/")
  pt_file_names = list.files(pt_path)
  pt_file_names = pt_file_names[grepl('.PitchTier', pt_file_names)]

  results = compute_distribution_features(pt_file_names, pt_path)
  write.csv(results, paste0(feartures_path, "distribution_features.csv"), row.names = FALSE)
}
