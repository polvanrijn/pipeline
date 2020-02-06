setwd(paste0( Sys.getenv("PT_DIR"), "Corpora/PELL/"))
source("../../Scripts/99_helpers/rename_files.R")
files = list.files('Audio/')
files = files[grepl('.wav', files)]
library(stringr)
library(dplyr)

file_df = as.data.frame(str_split_fixed(files, "_", 3))
names(file_df) = c("speaker", "emotion", "sentence")
file_df$old_name = files

# SENTENCE
file_df$sentence = str_replace(file_df$sentence, ".wav", "")
file_df$sentence = str_replace(file_df$sentence, "VX", "")
file_df$sentence_int = str_extract(file_df$sentence, "[0-9]+")

freq_df = as.data.frame(file_df %>% group_by(emotion, sentence_int, speaker) %>% summarise(count = n()))

file_df$sentence = str_pad(file_df$sentence_int, 2, pad = "0")

# INTENSITY
file_df$intensity = "XX"
freq_df = freq_df[freq_df$count == 2, ] # max 2 versions

file_df$repetition = 1

for (r in 1:nrow(freq_df)){
  cur_row = freq_df[r, ]
  idxs = which(file_df$speaker == cur_row$speaker & file_df$emotion == cur_row$emotion & file_df$sentence_int == cur_row$sentence_int)
  file_df$repetition[idxs[2]] = 2
}

file_df$old_name = str_replace(file_df$old_name, ".wav", "")

## RENAME FILES
file_df$new_name = paste(file_df$speaker,file_df$emotion, file_df$sentence, file_df$intensity, file_df$repetition, sep="_")

write.csv(file_df, "file_df.csv", row.names = F)

# Rename wavs
rename_files(paste0( Sys.getenv("PT_DIR"), "Corpora/PELL/Audio/"), ".wav", file_df$old_name, file_df$new_name)

# Rename TGs
rename_files(paste0( Sys.getenv("PT_DIR"), "Corpora/PELL/Audio/04_completed/"), ".TextGrid", file_df$old_name, file_df$new_name)

# Rename Fujisaki
fujisaki_path = paste0( Sys.getenv("PT_DIR"), "Corpora/PELL/Meta-data/Fujisaki/")
rename_files(fujisaki_path, ".4.txt", file_df$old_name, file_df$new_name)
rename_files(fujisaki_path, ".f0_ascii", file_df$old_name, file_df$new_name)
rename_files(fujisaki_path, ".PAC", file_df$old_name, file_df$new_name)

# Rename PitchTiers
pt_path = paste0( Sys.getenv("PT_DIR"), "Corpora/PELL/PitchTiers/08_manual_corrected/")
rename_files(pt_path, ".csv", file_df$old_name, file_df$new_name)
rename_files(pt_path, ".PitchTier", file_df$old_name, file_df$new_name)

# library(openxlsx)
# setwd("/Users/pol/owncloud/02_running_projects/02_PhD/Papers/dynamic_features/Corpora/PELL/Ratings/")
# ratings = read.xlsx("ratings.xlsx", sheet = 2)
# table(ratings[1,])
