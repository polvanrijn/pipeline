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
library(contouR)
#corpora = strsplit(Sys.getenv("CORPORA"), ",")[[1]]
corpora = "PELL_SCRAM"
pb = txtProgressBar(min = 0, max = length(corpora), initial = 0)
c = 0
for (corpus in corpora){
  c = c + 1
  wd = paste0( main_dir, 'Corpora/', corpus)
  base_directiory = paste0('"', wd, '/"')

  momel_dir = paste0(wd, "/Annotation/MOMEL_INTSINT/")
  if (dir.exists(momel_dir)){
    system(paste0("rm -r ", momel_dir))
  }
  
  cmd = paste0("cd ",  main_dir, "Scripts/03_feature_extraction; ", praat_path, ' --run ', '"Praat/compute_MOMEL_INTSINT.praat" ', base_directiory)
  system(cmd)
  
  feature = compute_intsint_features(momel_dir)
  names(feature)[2] = "MOMEL_INTSINT_count"
  
  momel_dir = paste0(wd, "/Annotation/INTSINT/")
  if (dir.exists(momel_dir)){
    system(paste0("rm -r ", momel_dir))
  }
  
  cmd = paste0("cd ",  main_dir, "Scripts/03_feature_extraction; ", praat_path, ' --run ', '"Praat/compute_INTSINT.praat" ', base_directiory)
  system(cmd)
  
  feature$stylized_INTSINT_count = compute_intsint_features(momel_dir)[, 2]
  
  write.csv(feature, paste0(wd, "/Features/INTSINT_MOMEL.csv"), row.names = F)
  
  setTxtProgressBar(pb, c/length(corpora))
}


