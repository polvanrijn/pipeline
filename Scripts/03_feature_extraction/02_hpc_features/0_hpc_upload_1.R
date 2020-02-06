source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/hpc.R"))
setup_connection()

hpc_execute("mkdir -p PitchTiers")
corpora = strsplit(Sys.getenv("CORPORA"), ",")[[1]]
for (corpus in corpora) {
  pt_path = paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/02_estimated/")
  files = list.files(pt_path)
  files = files[grep('.csv|.PitchTier', files)]

  # Create remote folder if needed
  remote_dir = paste0("~/PitchTiers/", corpus, "/")

  hpc_execute(paste("mkdir -p", remote_dir), T)
  # Alternative: hpc_copy_to(settings, pt_path, remote_dir)
  hpc_copy_to(paste0(pt_path, files), remote_dir)
}



hpc_execute("mkdir -p Fujisaki")
for (corpus in corpora) {
  Fujisaki_path = paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Meta-data/Fujisaki/")
  files = list.files(Fujisaki_path)
  files = files[grep('.PAC', files)]
  
  # Create remote folder if needed
  remote_dir = paste0("~/Fujisaki/", corpus, "/")
  
  hpc_execute(paste("mkdir -p", remote_dir), T)
  # Alternative: hpc_copy_to(pt_path, remote_dir)
  hpc_copy_to(paste0(Fujisaki_path, files), remote_dir)
}

hpc_make_dir("~/Sentence_wise_compression")
for (corpus in corpora) {
  remote_dir = paste0("~/Sentence_wise_compression/", corpus, "/")
  hpc_make_dir(remote_dir)
  hpc_copy_to(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/naive_sentence_wise_resampled.csv"), remote_dir)
  hpc_copy_to(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/pitch_settings.csv"), remote_dir)
}


hpc_make_dir("~/Words")
hpc_make_dir("~/file_df")
for (corpus in corpora) {
  tier_path = paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Annotation/Words/")
  files = list.files(tier_path)
  files = files[grep('.csv', files)]
  
  # Create remote folder if needed
  remote_dir = paste0("~/Words/", corpus, "/")
  hpc_make_dir(remote_dir)
  hpc_copy_to(paste0(tier_path, files), remote_dir)
  
  remote_dir = paste0("~/file_df/", corpus, "/")
  hpc_make_dir(remote_dir)
  hpc_copy_to(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/file_df.csv"), remote_dir)
}

disconnect()

