setwd(Sys.getenv("PT_DIR"))
man_dynamic = read.csv("Corpora/PELL_MAN/Features/true_dynamic_features.csv")
correct_names = function(df){
  # Remove duplicate PCs
  df = df[!grepl('w[1-3]_', names(df))]
  
  # Rename angle and cartasian PCs
  names(df) = stringr::str_replace(stringr::str_remove(names(df), "0_"), "reference_angle", "ang")
  PC_idx = which(substr(names(df), 1, 2) == "PC")
  PC_idx = min(PC_idx):((max(PC_idx)-min(PC_idx) - 1)/2 + min(PC_idx))
  names(df)[PC_idx] = stringr::str_replace(names(df)[PC_idx], '_', '_cart_')
  
  peak_idx = substr(names(df), 1, 5) == "peak_"
  names(df)[peak_idx] = paste0("hz_", names(df)[peak_idx])
  
  names(df)[names(df) == "a"] = "RMSE_intercept"
  names(df)[names(df) == "b"] = "RMSE_slope"
  names(df)[names(df) == "Aa_1"] = "Aa_last"
  return(df)
}
man_dynamic = correct_names(man_dynamic)

filenames = man_dynamic$filename
scram_dynamic = read.csv("Corpora/PELL_SCRAM/Features/true_dynamic_features.csv")
scram_dynamic = correct_names(scram_dynamic)

#summary_stats = NULL
man_stats = NULL
scram_stats = NULL
means = c()
for (f in filenames){
  pt_man = contouR::read_PitchTier(paste0("Corpora/PELL_MAN/PitchTiers/02_estimated/", f, ".PitchTier"))
  pt_scram = contouR::read_PitchTier(paste0("Corpora/PELL_SCRAM/PitchTiers/02_estimated/", f, ".PitchTier"))
  means = c(means, mean(pt_man$f))
  man_stats = rbind(man_stats, data.frame(
    sd = sd(pt_man$f),
    mean = mean(pt_man$f),
    min = min(pt_man$f),
    max = max(pt_man$f)
    #entropy = contouR::entropy(pt_man$f),
    #skewness = EnvStats::skewness(pt_man$f),
    #kurtosis = EnvStats::kurtosis(pt_man$f)
  ))
  
  scram_stats = rbind(scram_stats, data.frame(
    sd = sd(pt_scram$f),
    mean = mean(pt_scram$f),
    min = min(pt_scram$f),
    max = max(pt_scram$f)
    #entropy = contouR::entropy(pt_scram$f),
    #skewness = EnvStats::skewness(pt_scram$f),
    #kurtosis = EnvStats::kurtosis(pt_scram$f)
  ))
}


#man_dynamic = scale(man_dynamic[-1])
#scram_dynamic = scale(scram_dynamic[-1])

do_idxs = function(x, idx){
  if (is.null(dim(x))){
    return(x[idx])
  } else {
    # row
    return(x[idx, ])
  }
}

get_na_idx = function(x){
  if (is.null(dim(x))){
    return(!is.na(x))
  } else {
    # row
    return(apply(x, 1, function(x) (all(!is.na(x)))))
  }
}

na_rm_cor = function(x,y){
  if (is.null(ncol(x)) & is.null(ncol(y)) & length(x) != length(y)){
    stop()
  }
  idx = get_na_idx(x)
  x = do_idxs(x, idx)
  y = do_idxs(y, idx)

  idx = get_na_idx(y)
  y = do_idxs(y, idx)
  x = do_idxs(x, idx)
  
  return(cor(x,y))
}


get_corr  = function (df, abs_cor = TRUE){
  results = NULL
  for (col in names(df)[-1]){
    row = as.data.frame(na_rm_cor(df[col], scram_stats))
    if (abs_cor){
      row = abs(row)
    }
    row$feature = col
    results = rbind(results, row)
  }
  return(results)
}

library(ggplot2)
library(dplyr)
man_corrs = get_corr(man_dynamic)
man_corrs = reshape2::melt(man_corrs)
levels = c(
  rev(c("Ap", "num_phrases", "Aa_last", "Aa_first", "Momel_count", "stylised_count", "Aa_mean", "num_accents")),
  rev(c("sd_delta_tc", "mean_delta_tc", "sd_delta_F0", "mean_delta_F0", "num_ICCs", "num_neg_ICCs", "num_pos_ICCs", "min_max_slope", "naive_slope", "naive_intercept", "RMSE_slope", "RMSE_intercept")),
  rev(c("relative_harmonic", "smallest_harmonic", "st_peak_amplitude", "st_peak_frequency", "hz_peak_amplitude", "hz_peak_frequency", "PC2_ang_w3", "PC2_ang_w2", "PC2_ang_w1", "PC1_ang_w3", "PC1_ang_w2", "PC1_ang_w1", "PC2_cart_w3", "PC2_cart_w2", "PC2_cart_w1", "PC1_cart_w3", "PC1_cart_w2", "PC1_cart_w1"))
)
man_corrs$feature = factor(man_corrs$feature, levels = rev(levels))
ggplot(man_corrs) +
  #labs(x = "variable", y = "feature", fill = "value") +
  geom_tile(aes(x=variable, y=feature, fill=value)) +
  theme_minimal() +
  scale_fill_gradient(low = "white", high = "black", limits=c(0,1))

scram_corrs = get_corr(scram_dynamic)
scram_corrs = reshape2::melt(scram_corrs)
scram_corrs$feature = factor(scram_corrs$feature, levels = rev(levels))
ggplot(scram_corrs) +
  #labs(x = "variable", y = "feature", fill = "value") +
  geom_tile(aes(x=variable, y=feature, fill=value)) +
  theme_minimal() +
  scale_fill_gradient(low = "white", high = "black", limits=c(0,1))


apply(man_dynamic, 2, function(x) diff(range(as.numeric(x), na.rm = T)))
apply(scram_dynamic, 2, function(x) diff(range(as.numeric(x), na.rm = T)))

diff = apply(man_dynamic[-1] - scram_dynamic[-1], 2, function(x) round(mean(as.numeric(x), na.rm = T), 1))
diff = diff[!grepl("w\\d_PC", names(diff))]
diff[diff == 0] = NA
diff = log(abs(diff) + 1)
diff = as.data.frame(diff)

diff$type = factor(c(rep("shape", 18), rep("IP", 4), rep("slope", 5), rep("IP", 2), rep("slope", 6)), levels = c("IP", "slope", "shape"))
diff$name = factor(row.names(diff), levels = row.names(diff)[order(diff$type)])

ggplot(diff) +
  geom_tile(aes(x=name, y="test", fill=diff), color = "black") +
  theme_classic() +
  scale_fill_gradient(low = "white", high = "black", na.value = "red") +
  theme(axis.text.x = element_text(color = "grey20", angle = 45, hjust=0))

ggsave("~/Desktop/dynamic_features.pdf", device = cairo_pdf)

diff_sum = apply(summary_stats, 2, function(x) round(mean(as.numeric(x), na.rm = T), 1))
diff_sum[diff_sum == 0] = NA
diff_sum = as.data.frame(diff_sum)
diff_sum$name = factor(row.names(diff_sum), levels = row.names(diff_sum))
ggplot(diff_sum) +
  geom_tile(aes(x=name, y="Summary stats", fill=diff_sum)) +
  theme_classic() +
  scale_fill_gradient(low = "white", high = "black", na.value = "red")
ggsave("~/Desktop/summary_features.pdf", device = cairo_pdf)
