#corpora = c('PELL', 'CREMA-D', 'RAVDESS', 'SAVEE', 'TESS')
corpora = strsplit(Sys.getenv("CORPORA"), ",")[[1]]
for (corpus in corpora){
  tg_path = paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Annotation/TextGrids/")
  tier_path = paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Annotation/Words/")
  if (!dir.exists(tier_path)){
    dir.create(tier_path)
  }

  files = list.files(tg_path)
  files = files[grep('.TextGrid', files)]
  finished_files = list.files(tier_path)
  finished_files = finished_files[grep('.csv', finished_files)]

  files = files[!stringr::str_split_fixed(files, "\\.", 2)[,1] %in% stringr::str_split_fixed(finished_files, "\\.", 2)[,1]]
  for (f in files){
    #contouR::convert_tier_to_csv(paste0(tg_path, f), 'ORT-MAU', tier_path)
    contouR::convert_tier_to_csv(paste0(tg_path, f), 'words', tier_path)
    print(f)
  }
}
