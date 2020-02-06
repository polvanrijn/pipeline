main_dir = Sys.getenv("PT_DIR")
SMILExtract_path = paste0(main_dir, "Scripts/03_feature_extraction/opensmile-2.3.0/SMILExtract")
config_path = paste0(main_dir, "Scripts/03_feature_extraction/opensmile-2.3.0/config/gemaps/eGeMAPSv01a.conf")
corpora = strsplit(Sys.getenv("CORPORA"), ",")[[1]]
pb = txtProgressBar(min = 0, max = length(corpora), initial = 0)
c = 0

for (corpus in corpora){
  c = c + 1
  wd = paste0( main_dir, 'Corpora/', corpus)
  audio_dir = paste0(wd, "/Audio/")
  eGeMAPS_dir = paste0(wd, "/PitchTiers/03_eGeMAPS/")
  if (!dir.exists(eGeMAPS_dir)){
    dir.create(eGeMAPS_dir)
  }
  files = list.files(audio_dir, "*.wav")
  for (file in files){
    audio_path = paste0(audio_dir, file)
    file_basename = stringr::str_replace(file, ".wav", "")
    csv_path = paste0(eGeMAPS_dir, file_basename, ".csv")
    cd_cmd = paste0("cd ", eGeMAPS_dir, ";")
    cmd = paste(cd_cmd, SMILExtract_path, '-C', config_path, "-I", audio_path, "-csvoutput", csv_path)
    system(cmd)
  }

  files = list.files(eGeMAPS_dir, "*.csv")

  all_csvs = NULL
  for (file in files){
    base_filename = stringr::str_replace(file, ".csv", "")
    eGeMAPS = read.csv(paste0(eGeMAPS_dir, file),  sep = ";")
    eGeMAPS = eGeMAPS[3:90]
    meta_info = stringr::str_split(base_filename, "_")[[1]]
    eGeMAPS$speaker = meta_info[1]
    eGeMAPS$emotions = meta_info[2]
    eGeMAPS$sentence = meta_info[3]
    eGeMAPS$filename = base_filename
    all_csvs = rbind(all_csvs, eGeMAPS)
    file.remove(paste0(eGeMAPS_dir, file))
  }
  write.csv(all_csvs, paste0(wd, "/Features/eGeMAPS.csv"), row.names = F)

  setTxtProgressBar(pb, c/length(corpora))
}
