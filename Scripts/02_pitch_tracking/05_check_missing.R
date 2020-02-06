path = paste0( Sys.getenv("PT_DIR"), "Corpora/")
host = 'pol@127.0.0.1:2222'
passwd = 'test'

corpora = c('PELL', 'CREMA-D', 'RAVDESS', 'SAVEE', 'TESS')
for (corpus in corpora) {
  corpus_path = paste0(path, corpus, "/")
  pt_path = paste0(corpus_path, "PitchTiers/02_estimated/")
  pts = list.files(pt_path)
  pts = pts[grepl('.PitchTier', pts)]

  f0_ascii_path = paste0(corpus_path, 'Meta-data/Fujisaki/')
  missing_files = c()
  if (length(list.files(f0_ascii_path, ".PAC")) < length(pts) || length(list.files(f0_ascii_path, ".txt")) < length(pts)){
    warning(corpus)
    PACs = stringr::str_remove(list.files(f0_ascii_path, ".PAC"), ".PAC")
    f0_ascii = stringr::str_remove(list.files(f0_ascii_path, ".f0_ascii"), ".f0_ascii")
    files = f0_ascii[!f0_ascii %in% PACs]
    #contouR::estimate_fujisaki_parameters(files, f0_ascii_path, host, passwd)
    missing_files = TRUE
  }
  
  
}

