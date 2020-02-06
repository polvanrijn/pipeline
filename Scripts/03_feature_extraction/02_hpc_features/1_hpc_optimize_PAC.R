source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/hpc.R"))
start_octopus()

# Make sure directory PitchTiers exists
df = NULL
for (corpus in corpora) {
  Fujisaki_path = paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Meta-data/Fujisaki/")
  files = list.files(Fujisaki_path)
  files = files[grep('.PAC', files)]
  df = rbind(df, data.frame(
    corpus = corpus,
    name = stringr::str_remove(files, ".PAC")
  ))
}

optimizing_PAC = function(corpus, name){
  corpus = toString(corpus)
  name = toString(name)
  #telegram_send_message(paste(corpus, " ", name, "start exploring feature space"))
  library(contouR)
  
  # Defaults
  a_start = 0.5; a_step = 0.2; a_end = 4
  b_start = 15; b_step = 1; b_end = 35
  
  pt_path = paste0("~/PitchTiers/", corpus, "/")
  pt = read_PitchTier(paste0(pt_path, name, ".PitchTier"))
  Fujisaki_path = paste0("~/Fujisaki/", corpus, "/")
  full_path = paste0(Fujisaki_path, name, '.PAC')
  
  plot_df = compute_optimal_hyper_parameter(full_path, pt, a_start, a_step, a_end, b_start, b_step, b_end)
  #telegram_send_message(paste(corpus, "finished exploring feature space"))
  return(plot_df)
}

job = hpc_run(optimizing_PAC, list(df = df))
results = slurm_result(job)
disconnect()

if (length(results) != nrow(df)){
  stop()
}

for (cor in corpora){
  idxs = as.numeric(row.names(filter(df, corpus == cor)))
  plot_dfs = results[idxs]
  i = 0
  top_scores = NULL
  for (plot_df in plot_dfs){
    i = i + 1
    top_5 = plot_df[tail(rev(order(plot_df$RMSE)), 5), ]
    top_5$file = as.character(df$name[i])
    top_5$placement = 1:5
    top_scores = rbind(top_scores, top_5)
  }
  
  top_scores = cbind(top_scores, stringr::str_split_fixed(top_scores$file, "_", 3))
  names(top_scores)[6:8] = c("speaker", "emotion", "sentence_ID")
  
  write.csv(top_scores, paste0(Sys.getenv("PT_DIR"), "Corpora/", cor, "/PitchTiers/top_scores.csv"), row.names = F)
}

# Check if the order matches
count = 0
for (corpus in corpora){
  count = count + 1
  files = list.files(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/02_estimated/"))
  file = head(files[grep('.csv', files)], 1)
  if (file != paste0(results[[count]][1, "file"], ".csv")) {
    stop('This may not happen')
  }
  write.csv(results[[count]], paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/top_scores.csv"), row.names = F)
}
disconnect()
