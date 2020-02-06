source(paste0(Sys.getenv("PT_DIR"), "Scripts/99_helpers/get_sentences.R"))
sentences = get_sentences()

path = paste0( Sys.getenv("PT_DIR"), "Corpora/")
corpora = names(sentences)
for (corpus in corpora){
  setwd(paste0(path, corpus))
  sents = sentences[[corpus]]
  file_df = read.csv("file_df.csv")
  if (!dir.exists('Annotation')){
    dir.create('Annotation')
  }
  if (!dir.exists('Annotation/Sentences')){
    dir.create('Annotation/Sentences')
  }
  for (r in 1:nrow(file_df)){
    filename = file_df[r, "new_name"]
    sentence_idx = file_df[r, "sentence"]
    sentence = sents[sentence_idx]
    write.table(data.frame(sentence), paste0('Annotation/Sentences/', filename, '.txt'), row.names = F, col.names = F, quote = F)
  }
}


# The DB 'TESS' should be treated separately

setwd(paste0(path, 'TESS'))
file_df = read.csv("file_df.csv")
if (!dir.exists('Annotation')){
  dir.create('Annotation')
}
if (!dir.exists('Annotation/Sentences')){
  dir.create('Annotation/Sentences')
}
for (r in 1:nrow(file_df)){
  filename = file_df[r, "new_name"]
  word = file_df[r, "word"]
  sentence = paste0("Say the word ", word, ".")
  write.table(data.frame(sentence), paste0('Annotation/Sentences/', filename, '.txt'), row.names = F, col.names = F, quote = F)
}
