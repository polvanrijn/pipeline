source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/hpc.R"))
source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/classification.R"))
start_octopus()

# Make sure the latest classification_helpers.R is uploaded
hpc_copy_to(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/classification_helpers.R"), '~/classification_helpers.R')

classify = function(idx, part, by, csv, corp, feat){
  packrat::init("~/hpc_env/")
  library(dplyr)
  source('~/classification_helpers.R')
  col_info = list(
    partition = part,
    corpus = corp,
    cv = paste(c(by, idx), collapse = "-")
  )
  new_row = classification(csv, idx, feat,  by, column_info = col_info)
  return(new_row)
}

PELL = create_cross_fold_template("PELL", cross_validation_by = "sentence", num_folds = 30, feature_sets = c("baseline", "both", "new"))
RAVDESS = create_cross_fold_template("RAVDESS", cross_validation_by = "speaker", num_folds = 24, feature_sets = c("baseline", "both", "new"))
CREMA_D = create_cross_fold_template("CREMA-D", cross_validation_by = "speaker", num_folds = 91, feature_sets = c("baseline", "both", "new"))

PELL_AUTO_job = slurm_run(classify, PELL, jobname = "PELL_base_both_new")
RAVDESS_job = slurm_run(classify, RAVDESS, jobname = "RAVDESS_base_both_new")
CREMA_D_job = slurm_run(classify, CREMA_D, jobname = "CREMA-D_base_both_new")

PELL_base_both_new = get_result_as_df(PELL_AUTO_job)
RAVDESS_base_both_new = get_result_as_df(RAVDESS_job)
CREMA_D_base_both_new = get_result_as_df(CREMA_D_job)

write.csv(PELL_base_both_new, paste0(Sys.getenv("PT_DIR"), "Results/03_classification/PELL_AUTO_base_both_new.csv"), row.names = F)
write.csv(RAVDESS_base_both_new, paste0(Sys.getenv("PT_DIR"), "Results/03_classification/RAVDESS_base_both_new.csv"), row.names = F)
write.csv(CREMA_D_base_both_new, paste0(Sys.getenv("PT_DIR"), "Results/03_classification/CREMA-D_base_both_new.csv"), row.names = F)
