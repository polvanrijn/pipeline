setwd(Sys.getenv("PT_DIR"))
man_features = read.csv("Corpora/PELL/Features/manually_combined_features.csv")
man_features = man_features[1:89]
stats_df = NULL
for (f in man_features$filename){
  pt_man = contouR::read_PitchTier(paste0("Corpora/PELL_MAN/PitchTiers/02_estimated/", f, ".PitchTier"))
  stats_df = rbind(stats_df, data.frame(
    mean = mean(pt_man$f),
    max = max(pt_man$f),
    min = min(pt_man$f),
    sd = sd(pt_man$f)
  ))
}

man_features = cbind(man_features, stats_df)

meta_df = as.data.frame(stringr::str_split_fixed(man_features$filename, "_", 5)[, 1:5])
names(meta_df) = c("speaker", "emotion", "sentence", "intensity", "rep")

emotions = c("ANG", "DIS", "FER", "HAP", "NEU", "SAD")
row_idx = meta_df$emotion %in% emotions
man_features = man_features[row_idx, ]
meta_df = meta_df[row_idx, ]
meta_df$emotion = droplevels(meta_df$emotion)

features = man_features[names(man_features) != "filename"]

library(dplyr)
source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/classification_helpers.R"))
source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/classification.R"))
results = NULL

PELL = create_cross_fold_template("PELL", cross_validation_by = "sentence", num_folds = 30, feature_sets = c("null"))
PELL = PELL %>% arrange(as.numeric(as.character(idx)))
by = "sentence"

for (r in 1:nrow(PELL)){
  idx = PELL[r, "idx"]
  print(paste("Start:", idx))
  start_time = Sys.time()
  results = rbind(results, classification(features, meta_df, names(features), idx, by))
  print(paste("End:",  idx))
  end_time = Sys.time()
  print(end_time - start_time)
}

write.csv(results, paste0(Sys.getenv("PT_DIR"), "Results/03_classification/PELL_man_eGeMAPS+summary_stats.csv"), row.names = F)

# library(ggpubr)
# ggboxplot(results, x = 'col', y = 'sense_mean') +
#   # stat_compare_means(comparisons =  list( c("cor_0_4", "cor_1_0")), method = "t.test") +
#   scale_y_continuous(labels = scales::percent, limits = c(0, 1), breaks=seq(0,1,0.2)) +
#   labs(
#     x = "",
#     y = "Averaged sensitivity across emotions"
#   )
