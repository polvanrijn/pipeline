setwd(paste0( Sys.getenv("PT_DIR"), "Corpora/CREMA-D/"))
files = list.files('Audio/')
library(stringr)

file_df = as.data.frame(str_split_fixed(files, "_", 4))
names(file_df) = c("speaker", "sentence", "emotion", "intensity")
file_df$old_name = files

# SPEAKERS
speaker_numbers = 1:length(levels(file_df$speaker))
# Load the helper function
source("../../Scripts/99_helpers/number_to_two_letters.R")
speaker_labels = number_to_two_letters(speaker_numbers)
levels(file_df$speaker) = speaker_labels

# SENTENCE
levels(file_df$sentence) = str_pad(1:length(levels(file_df$sentence)), 2, pad = "0")


# EMOTION
levels(file_df$emotion) = c("ANG", "DIS", "FER", "HAP", "NEU", "SAD")

# INTENSITY
file_df$intensity = str_replace(file_df$intensity, ".wav", "")
file_df$old_name = str_replace(file_df$old_name, ".wav", "")

file_df$old_name[3213] = '1040_ITH_SAD_XX'
write.csv(file_df, "file_df.csv", row.names = F)

file_df$repetition = 1

## RENAME FILES
file_df$new_name = paste(file_df$speaker,file_df$emotion, file_df$sentence, file_df$intensity, file_df$repetition, sep="_")

setwd(paste0( Sys.getenv("PT_DIR"), "Corpora/CREMA-D/Audio/"))
file.rename(files, paste0(file_df$new_name, ".wav"))

## RENAME in votes
setwd(paste0( Sys.getenv("PT_DIR"), "Corpora/CREMA-D/Ratings/"))
tabulatedVotes = read.csv("tabulatedVotes.csv")

# Check if they are in the right order
if (all(file_df$old_name == levels(tabulatedVotes$fileName))){
  levels(tabulatedVotes$fileName) = file_df$old_name
}

tabulatedVotes = tabulatedVotes[, c(2:9, 11)]
names(tabulatedVotes) = c("ANG", "DIS", "FER", "HAP", "NEU", "SAD", "filename", "num_response", "majority_vote")
tabulatedVotes$majority_vote[grepl(':', tabulatedVotes$majority_vote)] = NA
tabulatedVotes$majority_vote = droplevels(tabulatedVotes$majority_vote)
levels(tabulatedVotes$majority_vote) = c("ANG", "DIS", "FER", "HAP", "NEU", "SAD")
write.csv(tabulatedVotes, "conf_matrix.csv", row.names = F)
