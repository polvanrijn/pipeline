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
source(paste0( Sys.getenv("PT_DIR"), "Scripts/99_helpers/corpus_meta.R"))
gender_per_corpus = get_gender_for_corpus()

corpora = c('PELL', 'CREMA-D', 'RAVDESS', 'SAVEE', 'TESS')
pb = txtProgressBar(min = 0, max = length(corpora), initial = 0) 
c = 0
for (corpus in corpora){
  c = c + 1
  wd = paste0( main_dir, 'Corpora/', corpus)
  base_directiory = paste0('"', wd, '/"')
  
  gender_for_corpus = gender_per_corpus[[corpus]]
  gender_df = NULL
  if (!is.null(gender_for_corpus$females)){
    gender_df = rbind(gender_df, data.frame(
      gender = "F",
      speakers = gender_for_corpus$females,
      corpus = corpus
    ))
  }
  
  if (!is.null(gender_for_corpus$males)){
    gender_df = rbind(gender_df, data.frame(
      gender = "M",
      speakers = gender_for_corpus$males,
      corpus = corpus
    ))
  }
  setwd(wd)
  pt_dir = paste0(wd, "/PitchTiers/")
  if (!dir.exists(pt_dir)){
    dir.create(paste0(wd, "/PitchTiers/"))
  }
  wide_dir = paste0(pt_dir, "01_wide/")
  if (dir.exists(wide_dir)){
    system(paste0("rm -r ", wide_dir))
  }
  
  write.table(gender_df, "PitchTiers/gender_df.csv", row.names = F, quote = F, sep="\t")
  
  cmd = paste0("cd ",  main_dir, "Scripts/02_pitch_tracking; ", praat_path, ' --run ', '"Praat/wide_spectrum_pitch_tier.praat" ', base_directiory)
  system(cmd)
  setTxtProgressBar(pb, c/length(corpora))
}

