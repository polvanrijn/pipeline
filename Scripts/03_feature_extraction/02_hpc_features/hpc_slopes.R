source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/hpc.R"))
setup_connection()

# Make sure directory PitchTiers exists
# hpc_execute("mkdir -p PitchTiers")
# corpora = strsplit(Sys.getenv("CORPORA"), ",")[[1]]
# for (corpus in corpora) {
#   pt_path = paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/02_estimated/")
#   files = list.files(pt_path)
#   files = files[grep('.csv', files)]
# 
#   # Create remote folder if needed
#   remote_dir = paste0("~/PitchTiers/", corpus, "/")
# 
#   hpc_execute(paste("mkdir -p", remote_dir), T)
#   # Alternative: hpc_copy_to(settings, pt_path, remote_dir)
#   hpc_copy_to(paste0(pt_path, files), remote_dir)
# }

regression_slope = function(corpus){
  library(contouR)
  remote_dir = paste0("~/PitchTiers/", corpus, "/")
  filenames = list.files(remote_dir)
  results = compute_regression_slopes(filenames, remote_dir)

  # telegram_send_message(paste(corpus, "finished"))
  return(results)
}

df = data.frame(corpus = corpora)
job = hpc_run(regression_slope, list(df = df))
results = slurm_result(job)

count = 0
for (corpus in corpora) {
  count = count + 1
  files = sort(list.files(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/02_estimated/")))
  file = head(files[grep('.csv', files)], 1)
  feature_df = results[[count]]
  if (file != head(sort(feature_df$name), 1)) {
    stop('This may not happen')
  }
  write.csv(feature_df, paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Features/slopes.csv"), row.names = F)
}

disconnect()

