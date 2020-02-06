source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/get_sentences.R"))
sentences = get_sentences()

# Do TESS
file_df = read.csv(paste0( Sys.getenv("PT_DIR"), "Corpora/TESS/file_df.csv"))
library(dplyr)
unique_sentence = file_df[!duplicated(file_df$sentence), ]
sentences[["TESS"]] = paste("Say the word", unique_sentence$word)

# Compute grouping_list
compute_grouping_list = function(corpus){
  # The blacklist is based on the following code:
  # sentence_split = stringr::str_split_fixed(unlist(sentences), " ", 3)
  # unique(tolower(sentence_split[,1]))

  # sent_idx = which(t(matrix(unlist(grouping_list),nrow = 3,ncol = 30))[,1] > 1)
  # sentences_with_w2 = sentences[["PELL"]][sent_idx]
  #
  # sent_idx = which(t(matrix(unlist(grouping_list),nrow = 3,ncol = 30))[,1] == 1)
  # sentences_with_w1 = sentences[["PELL"]][sent_idx]
  black_list_w1 = c("A", "The")

  lapply(strsplit(sentences[[corpus]], " "), function(x){
    w1 = 1
    if (x[1] %in% black_list_w1){
      w1 = 2
    }
    w2 = w1 + 1
    w3 = length(x)
    return(c(w1, w2, w3))
  })
}

compute_word_grouping_list = function(corpus){
  black_list_w1 = c("A", "The")

  clean_sentences = stringr::str_replace(sentences[[corpus]], "\\.", "")

  lapply(strsplit(clean_sentences, " "), function(x){
    w1 = 1
    if (x[1] %in% black_list_w1){
      w1 = 2
    }
    w2 = w1 + 1
    w3 = length(x)
    return(c(x[w1], x[w2], x[w3]))
  })
}


grouping_list = list(
  c(1, 2, 4),
  c(2, 3, 6),
  c(1, 2, 3),
  c(1, 2, 4),
  c(1, 2, 5),
  c(1, 2, 4),
  c(1, 2, 5),
  c(1, 2, 4),
  c(1, 2, 4),
  c(1, 2, 6),
  c(1, 2, 5),
  c(2, 3, 5),
  c(1, 2, 4),
  c(2, 3, 4),
  c(2, 3, 5),
  c(1, 2, 5),
  c(1, 2, 5),
  c(2, 3, 4),
  c(1, 2, 5),
  c(1, 2, 5),
  c(1, 2, 4),
  c(1, 2, 4),
  c(2, 3, 4),
  c(1, 2, 5),
  c(2, 3, 5),
  c(1, 2, 5),
  c(2, 3, 5),
  c(1, 2, 4),
  c(2, 3, 4),
  c(1, 2, 4)
)

sim_grouping_list = compute_grouping_list("PELL")
identical(sim_grouping_list, grouping_list) # Yields identical results




word_idxs = list()
words = list()
for (corpus in names(sentences)){
  word_idxs[[corpus]] = compute_grouping_list(corpus)
  words[[corpus]] = compute_word_grouping_list(corpus)
}

source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/hpc.R"))
settings = setup_connection()

word_idxs$PELL_MAN = word_idxs$PELL
word_idxs$PELL_SCRAM = word_idxs$PELL

words$PELL_MAN = words$PELL
words$PELL_SCRAM = words$PELL

hpc_copy_variable_to(word_idxs, 'word_idxs.RDS')
hpc_copy_variable_to(words, 'words.RDS')

hpc_execute("mkdir -p TextGrids", T)

#corpora = c('PELL', 'CREMA-D', 'RAVDESS', 'SAVEE', 'TESS')
for (corpus in corpora) {
  tg_path = paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Annotation/TextGrids/")
  files = list.files(tg_path)
  files = files[grep('.TextGrid', files)]

  # Create remote folder if needed
  remote_dir = paste0("~/TextGrids/", corpus, "/")

  hpc_execute(paste("mkdir -p", remote_dir), T)
  # Alternative: hpc_copy_to(settings, pt_path, remote_dir)
  hpc_copy_to(paste0(tg_path, files), remote_dir)
}

hpc_execute("mkdir -p file_df", T)
for (corpus in corpora) {
  remote_dir = paste0("~/file_df/", corpus, "/")
  hpc_execute(paste("mkdir -p", remote_dir), T)
  hpc_copy_to(paste0( Sys.getenv("PT_DIR"), "Corpora/", corpus, "/file_df.csv"), remote_dir)
}

compare_tg_labels = function(corpus){
  library(contouR)
  corpus = toString(corpus)

  tg_dir = paste0("~/TextGrids/", corpus, "/")
  words = readRDS('~/words.RDS')
  word_idxs = readRDS('~/word_idxs.RDS')
  file_df = read.csv(paste0("~/file_df/", corpus, "/file_df.csv"))
  file_df$sentence_ID = as.numeric(file_df$sentence)
  corpus_word_idxs = word_idxs[[corpus]]
  corpus_words = words[[corpus]]
  failed_files = c()
  for (r in 1:nrow(file_df)){
    sentence_ID = file_df[r, "sentence_ID"]
    filename = file_df[r, "new_name"]
    if (length(corpus_word_idxs) < sentence_ID){
      #telegram_send_message(paste(stringr::str_replace(filename, "_", " "), "missing in", corpus))
      failed_files = c(failed_files, filename)
    } else {
      word_idx = corpus_word_idxs[[sentence_ID]]
      tg_path = paste0(tg_dir, filename, ".TextGrid")
      if (!file.exists(tg_path)){
        #telegram_send_message(paste(stringr::str_replace(filename, "_", " "), "missing in", corpus))
        failed_files = c(failed_files, filename)
      } else {
        #telegram_send_message(tg_path)
        tryCatch({
          tg = read_TextGrid(tg_path)
          tier = tg$`ORT-MAU`
          real_labels = tier$label[tier$label != ""]
          real_labels = real_labels[word_idx]
          should_labels = corpus_words[[sentence_ID]]
          if (! identical(should_labels, real_labels)){
            telegram_send_message(paste(stringr::str_replace(filename, "_", " "), "did not match", corpus))
            failed_files = c(failed_files, filename)
          }
        }, error = function(ex){
          #telegram_send_message(paste("An error occured with", stringr::str_replace(filename, "_", "\\_")))
          failed_files = c(failed_files, filename)
        })
      }
    }
  }
  telegram_send_message(paste("Failed filenames:", paste(failed_files, collapse = ", "), "in corpus", corpus))
  Sys.sleep(0.05)
  telegram_send_message(paste(corpus, "finished checking labels in TGs"))
}

df = data.frame(corpus = corpora)
hpc_run(settings, compare_tg_labels, list(df = df))

# Problems in SAVEE: c(43, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 326, 327, 328, 329, 330, 403, 418, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449, 450)
file_df = read.csv(paste0( Sys.getenv("PT_DIR"), "Corpora/CREMA-D/file_df.csv"))
filename = "DJ_SAD_03_XX_1"
tg = read_TextGrid(paste0(Sys.getenv("PT_DIR"), "Corpora/CREMA-D/Annotation/TextGrids/", filename, ".TextGrid"))
# CREMA-D: 7141 in corpus

for (corpus in corpora){
  file_df = read.csv(paste0( Sys.getenv("PT_DIR"), "Corpora/", corpus, "/file_df.csv"))
  file_df$sentence_ID = as.numeric(file_df$sentence)
  corpus_word_idxs = word_idxs[[corpus]]
  corpus_words = words[[corpus]]
  for (r in 1:nrow(file_df)){
    sentence_ID = file_df[r, "sentence_ID"]
    word_idx = corpus_word_idxs[[sentence_ID]]
    filename = file_df[r, "new_name"]
    tg = read_TextGrid(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Annotation/TextGrids/", filename, ".TextGrid"))
    tier = tg$`ORT-MAU`
    real_labels = tier$label[tier$label != ""]
    real_labels = real_labels[word_idx]
    should_labels = corpus_words[[sentence_ID]]
    if (! identical(should_labels, real_labels)){
      print(should_labels)
      print(real_labels)
      print(filename)
    }
  }
}

