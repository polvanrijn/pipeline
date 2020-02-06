path = paste0( Sys.getenv("PT_DIR"), "Corpora/")
source(paste0( Sys.getenv("PT_DIR"), 'Scripts/99_helpers/resample_sentence_wise.R'))
library(contouR)
#corpora = c('PELL', 'CREMA-D', 'RAVDESS', 'SAVEE', 'TESS')
corpora = strsplit(Sys.getenv("CORPORA"), ",")[[1]]
for (corpus in corpora) {
  # Resample with Textgrids
  tryCatch({
    sentence_wide_df = resample_sentence_wise(path, corpus, '02_estimated', 'TextGrids', tier_name = "ORT-MAU")
    write.csv(sentence_wide_df, paste0(path, corpus, "/PitchTiers/sentence_wise_resampled.csv"), row.names = F)
  },
  error = function(er){
    warning(er)
  })

  # Resample naively without Textgrids
  tryCatch({
    sentence_wide_df_naive = naive_resample_sentence_wise(path, corpus, '02_estimated')
    write.csv(sentence_wide_df_naive, paste0(path, corpus, "/PitchTiers/naive_sentence_wise_resampled.csv"), row.names = F)
  },
  error = function(er){
    warning(er)
  })
}

