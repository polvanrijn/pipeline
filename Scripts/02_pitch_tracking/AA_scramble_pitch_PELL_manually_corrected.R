path = paste0( Sys.getenv("PT_DIR"), "Corpora/")
library(contouR)
library(rPraat)

corpus = "PELL_SCRAM"
corpus_path = paste0(path, corpus, "/")
pt_path = paste0(corpus_path, "PitchTiers/02_estimated/")
pt_file_names = list.files(pt_path)
pt_file_names = pt_file_names[grepl('.PitchTier', pt_file_names)]

for (pt_name in pt_file_names){
  pt_file_path = paste0(pt_path, pt_name)
  pt = read_PitchTier(pt_file_path)
  set.seed(1)
  pt$f = sample(pt$f)
  pt.write(pt, pt_file_path)
  write.csv(pt, paste0(stringr::str_remove(pt_file_path, "\\.PitchTier"), ".csv"), row.names = F)
}
