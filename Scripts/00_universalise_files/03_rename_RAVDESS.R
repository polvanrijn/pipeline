setwd(paste0( Sys.getenv("PT_DIR"), "Corpora/RAVDESS/"))

files = list.files('Audio/')
files = files[grepl('.wav', files)]
library(stringr)
library(dplyr)

file_df = as.data.frame(str_split_fixed(files, "-", 7))
names(file_df) = c("modality", "channel", "emotion", "intensity", "sentence", "repetition", "speaker")
file_df$old_name = files
file_df$old_name = str_replace(file_df$old_name, ".wav", "")

# SPEAKER
file_df$speaker = str_replace(file_df$speaker, ".wav", "")
l = LETTERS[as.factor(file_df$speaker)]
file_df$speaker = paste0(l, l)

# SENTENCE √

# EMOTION
levels(file_df$emotion) = c("NEU", "CAL", "HAP", "SAD", "ANG", "FER", "DIS", "SUR")

# INTENSITY
levels(file_df$intensity) = c("MI", "HI", "XX")
file_df$intensity[file_df$emotion == "NEU"] = "XX"

# REPETITION
levels(file_df$repetition) = 1:length(levels(file_df$repetition))

## RENAME FILES
file_df$new_name = paste(file_df$speaker,file_df$emotion, file_df$sentence, file_df$intensity, file_df$repetition, sep="_")

write.csv(file_df, "file_df.csv", row.names = F)


source(paste0( Sys.getenv("PT_DIR"), "Scripts/99_helpers/rename_files.R"))
rename_files(paste0( Sys.getenv("PT_DIR"), "Corpora/RAVDESS/Audio/"), ".wav", file_df$old_name, file_df$new_name)
