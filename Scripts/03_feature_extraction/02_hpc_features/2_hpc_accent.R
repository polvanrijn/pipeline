source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/hpc.R"))
setup_connection()

hpc_make_dir("~/top_scores")
corpora = strsplit(Sys.getenv("CORPORA"), ",")[[1]]
for (corpus in corpora) {
  remote_dir = paste0("~/top_scores/", corpus, "/")
  hpc_make_dir(remote_dir)
  hpc_copy_to(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/top_scores.csv"), remote_dir)
}

accent_features = function(corpus) {
  library(contouR)
  corpus = toString(corpus)
  top_scores = read.csv(paste0("~/top_scores/", corpus, "/top_scores.csv"))
  Fujisaki_path = paste0("~/Fujisaki/", corpus, "/")
  #telegram_send_message(paste(corpus, "start accent"))
  accent_features = compute_accent_features(top_scores, Fujisaki_path)
  accent_features$filename = filter(top_scores, placement == 1)$file
  write.csv(accent_features, paste0("~/top_scores/", corpus, "/accent.csv"), row.names = F)
  #telegram_send_message(paste(corpus, "end accent"))
  return(accent_features)
}

df = data.frame(corpus = corpora)
job = hpc_run(accent_features, list(df = df))
results = slurm_result(job)

c = 0
for (result in results) {
  c = c + 1
  write.csv(result, paste0(Sys.getenv("PT_DIR"), "Corpora/", corpora[c], "/Features/accent.csv"), row.names = F)
  #hpc_copy_from(paste0("~/top_scores/", corpus, "/accent.csv"), paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Features/"))
}

