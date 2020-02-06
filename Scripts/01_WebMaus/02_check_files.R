path = paste0( Sys.getenv("PT_DIR"), "Corpora/")
setwd(path)
source('../Scripts/99_helpers/webmaus_helpers.R')

# Go through each corpus
corpora = c('CREMA-D', 'RAVDESS', 'SAVEE', 'TESS')
for (corpus in corpora){
  num_missing_files = 0
  setwd(paste0(path, corpus))
  
  sent_files = str_replace_all(list.files('Annotation/Sentences/'), "\\.txt", "")
  tg_files = str_replace_all(list.files('Annotation/TextGrids/'), "\\.TextGrid", "")
  if (file.exists('missing_files.csv')){
    missing_files = read.csv('missing_files.csv')
    
    # Retry downloading
    for (f_name in missing_files$f_name){
        download_webmaus(f_name, check_missing_files = FALSE)
    }
    
    sent_files = str_replace_all(list.files('Annotation/Sentences/'), "\\.txt", "")
    tg_files = str_replace_all(list.files('Annotation/TextGrids/'), "\\.TextGrid", "")
    
    num_missing_files = abs(length(sent_files) - length(tg_files))
    
    sent_files = sent_files[!sent_files %in% missing_files$f_name]
    tg_files = tg_files[!tg_files %in% missing_files$f_name]
  }
  if (length(sent_files) != length(tg_files)){
    stop("This may not happen!")
  } else{
    print(paste(corpus, "finished with", num_missing_files, "missing files"))
  }
}
