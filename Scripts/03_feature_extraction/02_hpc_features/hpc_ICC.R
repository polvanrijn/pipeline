source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/hpc.R"))
setup_connection()

corpora = strsplit(Sys.getenv("CORPORA"), ",")[[1]]
df = data.frame(corpus = corpora)

ICC_computation = function(corpus){
  library(contouR)
  corpus = toString(corpus)
  pt_path = paste0("~/PitchTiers/", corpus, "/")
  files = list.files(pt_path)
  files = files[grep('.csv', files)]
  out = compute_EAC_ICCs(files, pt_path)
  #telegram_send_message(paste(corpus, "finished"))
  return(out)
}

job = hpc_run(ICC_computation, list(df = df))
results = slurm_result(job)
# Check if the order matches
count = 0
for (corpus in corpora){
  count = count + 1
  files = list.files(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/02_estimated/"))
  file = head(files[grep('.csv', files)], 1)
  if (file != results[[count]][1, "name"]) {
    stop('This may not happen')
  }
  write.csv(results[[count]], paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Features/ICCs.csv"), row.names = F)
}
disconnect()
