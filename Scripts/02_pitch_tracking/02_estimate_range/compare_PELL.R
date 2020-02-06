library(contouR)
library(rPraat)
path = paste0( Sys.getenv("PT_DIR"), "Corpora/PELL/PitchTiers/")
setwd(path)

downsample = function(x_short, y_short, x_long, y_long){
  last_val = tail(y_long, 1)
  interpol = approxfun(x_long, y_long)
  # predict them
  y_pred = interpol(x_short)

  not_na_idx = which(!is.na(y_pred))
  if (length(not_na_idx) != (max(not_na_idx) - min(not_na_idx) + 1)){
    stop()
  } else{
    x_short = x_short[not_na_idx]
    y_short = y_short[not_na_idx]
    y_pred = y_pred[not_na_idx]
  }

  if (any(is.na(y_pred))){
    stop('May not contain any NA!')
  }

  return(list(x_short = x_short, y_short = y_short, y_pred = y_pred))
}

compute_samp_rate = function(pt){
  return(median(diff(pt$t, lag = 1)))
}

compute_baseline = function(old, new, label){
  resample = T
  if (length(new$f) > length(old$f)){
    retrn = downsample(old$t, old$f, new$t, new$f)
    new_f = retrn$y_pred
    old_f = retrn$y_short
  } else if (length(new$f) < length(old$f)){
    retrn = downsample(new$t, new$f, old$t, old$f)
    old_f = retrn$y_pred
    new_f = retrn$y_short
  } else{
    old_f = old$f
    new_f = new$f
    resample = F
  }

  if (!resample){
    message(paste("Resampled", fn))
    t = old$t
  } else{
    t = retrn$x_short
  }

  diff = new_f - old_f

  RMSE = contouR::RMSE(new_f, old_f)

  if (RMSE < 100 & RMSE > 50){
    plot(t, new_f, type = "l", main = paste(fn, label))
    lines(t, old_f, col = "red")
  }

  df = rbind(df,
             data.frame(
               label = label,
               RMSE = contouR::RMSE(new_f, old_f),
               correlation = cor(new_f, old_f),
               outlier_5hz = length(which(abs(diff) > 5))/length(diff),
               emotion = splits[2],
               speaker = splits[1]
             ))
  return(df)
}

filenames_new = get_pt_filnames(paste0(path, "02_estimated"))
filenames_old = get_pt_filnames(paste0(path, "08_manual_corrected"))

file_df = read.csv(paste0(path, "../file_df.csv"))
file_df$old_name = paste0(file_df$old_name, ".PitchTier")
file_df$new_name = paste0(file_df$new_name, ".PitchTier")

df = NULL
for (fn in filenames_old){
  splits = stringr::str_split(fn, "_", 3)[[1]]
  old_name = file_df[file_df$new_name == fn, "old_name"]

  old_wide = read_PitchTier(paste0(path, "05_extended_range/", old_name))
  new_wide = read_PitchTier(paste0(path, "01_wide/", fn))
  df = compute_baseline(old_wide, new_wide, "compare_wide")

  old_estimate = read_PitchTier(paste0(path, "07_final/", old_name))
  new_estimate = read_PitchTier(paste0(path, "02_estimated/", fn))

  delooze_2010_estimate = read_PitchTier(paste0(path, "delooze2010/", fn))
  hirst_2011_estimate = read_PitchTier(paste0(path, "02_estimated/", fn))

  baseline = read_PitchTier(paste0(path, "08_manual_corrected/", fn))
  df = compute_baseline(old_estimate, baseline, "old_estimate")
  df = compute_baseline(new_estimate, baseline, "new_estimate")
  df = compute_baseline(delooze_2010_estimate, baseline, "hirst")
  df = compute_baseline(hirst_2011_estimate, baseline, "delooze")
}

df$correlation = abs(df$correlation)
long_df = tidyr::gather(df, measure, value, RMSE:outlier_5hz)

library(ggplot2)
library(dplyr)
filter(long_df, )

ggplot(filter(long_df, measure=="correlation")) +
  geom_boxplot(aes(x = emotion, y = value)) +
  facet_wrap( ~ label) +
  ylim(0, 1)

ggplot(filter(long_df, measure=="outlier_5hz")) +
  geom_boxplot(aes(x = emotion, y = value)) +
  facet_wrap(~ label) +
  ylim(0, 1)

ggplot(filter(long_df, measure=="RMSE")) +
  geom_boxplot(aes(x = emotion, y = value)) +
  facet_wrap( ~ label)

outlier_5hz = ggplot(filter(long_df, label == "new_estimate", measure == "outlier_5hz")) +
  geom_boxplot(aes(x = emotion, y = value)) +
  ylim(0,1) +
  labs(
    title = "Percentage pitch points > 5 Hz",
    caption = "Percentage of pitch points that deviate more than 5 Hz from the baseline; dots represent single fragments"
  )

RMSE = ggplot(filter(long_df, label == "new_estimate", measure == "RMSE")) +
  geom_boxplot(aes(x = emotion, y = value)) +
  labs(
    title = "Root mean square error",
    caption = "Average deviation per pitch point; dots represent single fragments"
  )

correlation = ggplot(filter(long_df, label == "new_estimate", measure == "correlation")) +
  geom_boxplot(aes(x = emotion, y = value)) +
  ylim(0,1) +
  labs(
    title = "Correlation",
    caption = "Correlations between single PitchTiers; dots represent single fragments"
  )
library(ggpubr)

ggarrange(outlier_5hz, RMSE, correlation,
          labels = c("A", "B", "C"),
          nrow = 1)

ggsave(paste0( Sys.getenv("PT_DIR"), "Scripts/02_pitch_tracking/comparison.pdf"), width=17, device = cairo_pdf)
