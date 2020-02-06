TESS_path = paste0( Sys.getenv("PT_DIR"), "Corpora/TESS/")
setwd(TESS_path)

files = list.files('Audio/')
files = files[grepl('.wav', files)]
library(stringr)
library(dplyr)

file_df = as.data.frame(str_split_fixed(files, "_", 3))
names(file_df) = c("speaker", "word",  "emotion")

file_df$old_name = files
file_df$old_name = str_replace(file_df$old_name, ".wav", "")

# SPEAKER
file_df$speaker = as.factor(substr(file_df$speaker, 1, 2))

# SENTENCE
file_df$sentence = file_df$word
# Load the helper function
source("../../Scripts/99_helpers/number_to_two_letters.R")
levels(file_df$sentence) = number_to_two_letters(sentence_numbers)


# EMOTION
file_df$emotion = as.factor(str_replace(file_df$emotion, ".wav", ""))
levels(file_df$emotion) = c("ANG", "DIS", "FER", "HAP", "NEU", "SUR", "SAD")

# INTENSITY
intensity = "XX"

# REPETITION
repetition = 1

## RENAME FILES
file_df$new_name = paste(file_df$speaker,file_df$emotion, file_df$sentence, intensity, repetition, sep="_")

write.csv(file_df, "file_df.csv", row.names = F)

source(paste0( Sys.getenv("PT_DIR"), "Scripts/99_helpers/rename_files.R"))
rename_files(paste0( Sys.getenv("PT_DIR"), "Corpora/TESS/Audio/"), ".wav", file_df$old_name, file_df$new_name)
