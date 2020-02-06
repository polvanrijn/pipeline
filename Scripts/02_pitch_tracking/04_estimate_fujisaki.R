path = paste0( Sys.getenv("PT_DIR"), "Corpora/")
host = 'pol@127.0.0.1:2222'
passwd = 'test'

corpora = strsplit(Sys.getenv("CORPORA"), ",")[[1]]
for (corpus in corpora) {
  corpus_path = paste0(path, corpus, "/")
  pt_path = paste0(corpus_path, "PitchTiers/02_estimated/")
  pts = list.files(pt_path)
  pts = pts[grepl('.PitchTier', pts)]

  # Create meta-data
  dirs_exist = c('Meta-data', 'Meta-data/Fujisaki')
  for (d in dirs_exist) {
    d_path = paste0(corpus_path, d)
    if (!dir.exists(d_path)) {
      dir.create(d_path)
    }
  }

  f0_ascii_path = paste0(corpus_path, 'Meta-data/Fujisaki/')
  for (pt_name in pts) {
    pt = contouR::read_PitchTier(paste0(pt_path, pt_name))
    # Convert Pitch Tiers to f0_asci
    pt_strip_name = paste0(f0_ascii_path, strsplit(pt_name, ".PitchTier")[[1]][1], '.f0_ascii')
    contouR::write_f0_ascii(pt$t, pt$f, pt_strip_name)
  }

  # Compute PAC files
  files = list.files(f0_ascii_path)
  files = stringr::str_split_fixed(files[grepl('.f0_ascii', files)], '.f0_ascii', 2)[,1]
  contouR::estimate_fujisaki_parameters(files, f0_ascii_path, host, passwd)
}

