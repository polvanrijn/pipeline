source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/hpc.R"))
setup_connection()

corpora = strsplit(Sys.getenv("CORPORA"), ",")[[1]]

# Upload the resampled files
# hpc_make_dir("~/Sentence_wise_compression")
# for (corpus in corpora) {
#   remote_dir = paste0("~/Sentence_wise_compression/", corpus, "/")
#   hpc_make_dir(remote_dir)
#   hpc_copy_to(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/naive_sentence_wise_resampled.csv"), remote_dir)
#   hpc_copy_to(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/pitch_settings.csv"), remote_dir)
# }

freq_analysis = function(corpus){
  library(contouR)
  library(dplyr)
  corpus = toString(corpus)

  do_freq_analysis = function(df, speaker_floor, suffix = ""){
    padding = ceiling(max(df$t)) + 6
    foi = seq(0, 34, 0.25)
    summary_df = NULL
    retrn_df = NULL
    for (fl in unique(speaker_floor$floor)){
      speakers = filter(speaker_floor, floor == fl)$speaker
      sel_df = df %>% filter(speaker %in% speakers)
      dt = sel_df %>% group_by(filename) %>% summarise(f = list(f), t = list(t))
      powspec = contouR::frequency_analysis(dt$f, dt$t, padding, foi)

      lookup_df = df[!duplicated(df$filename), ] %>% filter(speaker %in% speakers)

      retrn_df = rbind(retrn_df, do.call("rbind",
              lapply(1:nrow(powspec), function(r){
                pow = powspec[r, ]
                return(data.frame(
                  speaker = lookup_df[r, "speaker"],
                  emotion = lookup_df[r, "emotion"],
                  sentence = lookup_df[r, "sentence"],
                  #compression = lookup_df[r, "compression"],
                  filename = lookup_df[r, "filename"],
                  max_rows = max(pow),
                  t_max_rows = foi[which(pow == max(pow))],
                  floor = fl
                ))
              })
      ))

      summary_df = rbind(summary_df,
                         data.frame(
                           foi = foi,
                           amp = colMeans(powspec),
                           floor = fl
                         ))
      #telegram_send_message(paste(corpus, "finished floor", fl))
    }

    library(ggplot2)
    summary_df$floor = as.factor(summary_df$floor)
    p = ggplot(summary_df) +
      geom_line(aes(x = foi, y = amp, color = floor))


    plot_name = paste0(corpus, "_freq", suffix, ".pdf")

    ggsave(plot_name, plot = p)
    #telegram_upload_file(plot_name)

    names(retrn_df) = paste0(names(retrn_df), suffix)
    return(retrn_df)
  }


  resamp_df = read.csv(paste0("~/Sentence_wise_compression/", corpus, "/naive_sentence_wise_resampled.csv"))
  pitch_settings = read.table(paste0("~/Sentence_wise_compression/", corpus, "/pitch_settings.csv"), sep = "\t", header = T)
  speaker_floor = pitch_settings %>% group_by(speaker) %>% summarise(floor = floor[1])

  retrn_df = do_freq_analysis(resamp_df, speaker_floor)

  resamp_df_st = resamp_df
  resamp_df_st$f = f2st(resamp_df_st$f)
  retrn_df_st = do_freq_analysis(resamp_df_st, speaker_floor, "_st")

  retrn_df = cbind(retrn_df, retrn_df_st)

  return(retrn_df)
}
df = data.frame(corpus = corpora)
job = hpc_run(freq_analysis, list(df = df))
results = slurm_result(job)

count = 0
for (corpus in corpora) {
  count = count + 1
  files = sort(list.files(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/PitchTiers/02_estimated/")))
  file = head(files[grep('.csv', files)], 1)
  feature_df = results[[count]]
  if (file != paste0(head(sort(feature_df$filename), 1), ".csv")) {
    stop('This may not happen')
  }
  write.csv(feature_df, paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Features/frequency.csv"), row.names = F)
}
