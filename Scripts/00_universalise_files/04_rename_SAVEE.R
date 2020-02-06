path = paste0( Sys.getenv("PT_DIR"), "Corpora/SAVEE/")
setwd(path)


right_substr <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}
left_substr <- function(x, n){
  substr(x, 1, nchar(x) -n)
}

library(plyr)

speakers = c("DC", "JE", "JK", "KL")
repetition = 1
intensity = "XX"

if (!dir.exists("Audio")){
  dir.create("Audio")
}

filenames = c()
for (speaker in speakers){
  files = list.files(paste0("AudioData/", speaker))
  files = str_replace(files, ".wav", "")
  sentences = right_substr(files, 2)
  emotions = as.factor(left_substr(files, 2))
  emotions = mapvalues(emotions, from = c("a", "d", "f", "h", "n", "sa", "su"), to = c("ANG", "DIS", "FER", "HAP", "NEU", "SAD", "SUR"))
  new_names = paste(speaker, emotions, sentences, intensity, repetition, sep="_")
  filenames = c(filenames, new_names)
  file.rename(paste0(path, "AudioData/", speaker, "/", files, ".wav"), paste0(path, "Audio/", new_names, ".wav"))
  annotation_files = paste0(as.factor(left_substr(files, 2)),as.numeric(sentences))
  for (subfolder in c("FrequencyTrack", "PhoneticLabel")){
    if (!dir.exists(subfolder)){
      dir.create(subfolder)
    }
    old_files = paste0(path, "Annotation/", speaker,  "/", subfolder, "/", annotation_files, ".txt")

    file.rename(old_files, paste0(path, subfolder, "/", new_names, ".txt"))
  }

}

file_df = data.frame(new_names = filenames)
write.csv(file_df, "file_df.csv", row.names = F)

library(dplyr)
filter(file_df, sentence > 3 & sentence <= 15)
rep2_NEU = filter(file_df, sentence > 15 & sentence <= 18)
rep2_NEU$repetition = 2
rep2_NEU$sentence = rep2_NEU$sentence - 15
old_names = as.character(rep2_NEU$new_name)
rep2_NEU$new_name = paste(rep2_NEU$speaker, rep2_NEU$emotion, stringr::str_pad(rep2_NEU$sentence, 2, pad = "0"), rep2_NEU$intensity, rep2_NEU$repetition, sep="_")

folder_ext = list(
  list(
    folder = "Annotation/Setentences/",
    ext = ".txt"
  ),
  list(
    folder = "Audio/",
    ext = ".wav"
  ),
  list(
    folder = "Annotation/TextGrids/",
    ext = ".TextGrid"
  ),
  list(
    folder = "Annotation/Words/",
    ext = ".csv"
  ),
  list(
    folder = "Meta-data/Fujisaki/",
    ext = ".4.txt"
  ),
  list(
    folder = "Meta-data/Fujisaki/",
    ext = ".f0_ascii"
  ),
  list(
    folder = "Meta-data/Fujisaki/",
    ext = ".PAC"
  ),
  list(
    folder = "PhoneticLabel/",
    ext = ".txt"
  ),
  list(
    folder = "PitchTiers/01_wide/",
    ext = ".PitchTier"
  ),
  list(
    folder = "PitchTiers/02_estimated/",
    ext = ".PitchTier"
  )
)
for (l in folder_ext){
  file.rename(paste0(path, l$folder, old_names, l$ext), paste0(path, l$folder, rep2_NEU$new_name, l$ext))
}

remove_files = filter(file_df, sentence > 4)$new_name
for (l in folder_ext){
  file.remove(paste0(path, l$folder, remove_files, l$ext))
}


sentences = read.csv(paste0(path, "sentences.csv"), sep = ";")
for (r in 1:nrow(sentences)){
  row_equal = c()
  sents = c()
  for (c in 1:(ncol(sentences) - 1)){
    row_equal = c(row_equal, sentences[r, c] == sentences[r, c + 1])
    sents = c(sents, as.character(sentences[r, c]))
  }
  sents = c(sents, as.character(sentences[r, c + 1]))
  if (!all(row_equal)){
    print(paste("Sentence", r))
    print(unique(sents))
  }
}

file_df = filter(file_df, !new_name %in% remove_files)

write.csv(filter(file_df, sentence != 4), paste0(path, "file_df.csv"), row.names = F)
