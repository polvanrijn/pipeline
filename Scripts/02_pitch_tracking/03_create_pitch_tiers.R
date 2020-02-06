sysinf <- Sys.info()
if (!is.null(sysinf)){
  os <- sysinf['sysname']
  #praat_path = '"C:\Program Files\Praat.exe"'
  if (os == 'Darwin')
    praat_path = '/Applications/Praat.app/Contents/MacOS/Praat'
} else { ## mystery machine
  os <- .Platform$OS.type
  if (grepl("^darwin", R.version$os))
    praat_path = '/Applications/Praat.app/Contents/MacOS/Praat'
  if (grepl("linux-gnu", R.version$os))
    praat_path = '/usr/bin/praat'
}

main_dir = Sys.getenv("PT_DIR")

corpora = c('CREMA-D', 'RAVDESS', 'SAVEE', 'TESS', 'PELL')

pb = txtProgressBar(min = 0, max = length(corpora), initial = 0) 
c = 0
for (corpus in corpora){
  c = c + 1
  wd = paste0( main_dir, 'Corpora/', corpus)
  base_directiory = paste0('"', wd, '/"')

  est_dir = paste0(wd, "/PitchTiers/02_estimated/")
  if (dir.exists(est_dir)){
    system(paste0("rm -r ", est_dir))
  }
  
  cmd = paste0("cd ",  main_dir, "Scripts/02_pitch_tracking; ", praat_path, ' --run ', '"Praat/compute_pitch_tier.praat" ', base_directiory)
  system(cmd)
  setTxtProgressBar(pb, c/length(corpora))
}

