library(dplyr)
# Make sure you have computed the new features for both the original and scrambled contour:
feat_man = read.csv(paste0(Sys.getenv("PT_DIR"), "Corpora/PELL_MAN/Features/dynamic_features.csv"))
feat_scram = read.csv(paste0(Sys.getenv("PT_DIR"), "Corpora/PELL_SCRAM/Features/dynamic_features.csv"))

# Load the scripts to do the classification
source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/classification_helpers.R"))
source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/classification.R"))
results = NULL

# Create a cross validation template
PELL = create_cross_fold_template("PELL", cross_validation_by = "sentence", num_folds = 30, feature_sets = c("null"))
PELL = PELL %>% arrange(as.numeric(as.character(idx)))
by = "sentence"

# Specify groups (possibly check names)
col_name_list = list(
  "Slope and Intercept" = c("a", "b", "naive_intercept", "naive_slope", "min_max_slope", "num_pos_ICCs", "num_neg_ICCs", "mean_delta_F0", "sd_delta_F0"),
  "Shape" = c("PC1_w0_1", "PC1_w0_2", "PC1_w0_3", "PC2_w0_1", "PC2_w0_2", "PC2_w0_3", "PC1_reference_angle_w0_1", "PC1_reference_angle_w0_2", "PC1_reference_angle_w0_3", "PC2_reference_angle_w0_1", "PC2_reference_angle_w0_2", "PC2_reference_angle_w0_3", "peak_frequency", "peak_amplitude", "st_peak_frequency", "st_peak_amplitude"),
  "IP" = c("Aa_mean", "Aa_1", "Aa_last", "num_accents", "num_phrases", "Ap")
)

for (dataset in c("PELL_SCRAM", "PELL_MAN")){
  csv_path = paste0(Sys.getenv("PT_DIR"), "Corpora/", dataset,  "/Features/true_dynamic_features.csv")
  rtrn = load_features_and_meta(csv_path)
  features = rtrn$features
  meta_df = rtrn$meta_df
  labels = meta_df$emotion

  for (l in 1:length(col_name_list)){
    name = names(col_name_list)[l]
    col_names = col_name_list[[name]]
    print(name)
    print(col_names)
    for (r in 1:nrow(PELL)){
      idx = PELL[r, "idx"]
      print(paste("Start:", dataset, idx, name))
      start_time = Sys.time()
      results = rbind(results, classification(features, meta_df, col_names, idx, by, column_info = list('name' = name, 'dataset' = dataset)))
      print(paste("End:", dataset, idx, name))
      end_time = Sys.time()
      print(end_time - start_time)
    }
  }
}

write.csv(results, paste0(Sys.getenv("PT_DIR"), "Results/03_classification/PELL_SCRAMBLE.csv"), row.names = F)
