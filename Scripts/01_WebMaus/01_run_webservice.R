path = paste0( Sys.getenv("PT_DIR"), "Corpora/")
setwd(path)

source('../Scripts/99_helpers/webmaus_helpers.R')

# Some fixed settings
api_URL = 'https://clarin.phonetik.uni-muenchen.de/BASWebServices/services/runMAUSBasic'
#language_param = 'LANGUAGE=deu'
language_param = 'LANGUAGE=eng-GB'

if (file.exists('missing_files.csv')){
  missing_files = read.csv('missing_files.csv')
} else {
  missing_files = NULL
}

# Go through each corpus
corpora = c('CREMA-D', 'RAVDESS', 'SAVEE', 'TESS', 'PELL')
for (corpus in corpora){
  setwd(paste0(path, corpus))
  
  if (!dir.exists('Annotation/TextGrids')){
    dir.create('Annotation/TextGrids')
  }
  
  
  filenames = list.files('Annotation/TextGrids')
  
  file_df = read.csv("file_df.csv")
  for (f_name in file_df$new_name){
    if (!(paste0(f_name, '.TextGrid') %in% filenames || f_name %in% missing_files$f_name)){
      text_param = paste0('TEXT=@Annotation/Sentences/', f_name, '.txt')
      signal_param = paste0('SIGNAL=@Audio/', f_name, '.wav')
      cmd = paste("curl --silent -X POST -H 'content-type: multipart/form-data'", "v=1 -F", language_param, "-F OUTSYMBOL=ipa -F",  text_param, '-F', signal_param,  api_URL)
      url_to_dwnld = extract_url(sys_call(cmd))
      
      if (url_to_dwnld == ""){
        warning(paste("Could not download", f_name, corpus))
        missing_files = rbind(missing_files, data.frame(
          f_name = f_name,
          corpus = corpus,
          type = "TextGrid"
        ))
        write.csv(missing_files, 'missing_files.csv', row.names = F)
      } else {
        print(paste("Download:", f_name))
        download.file(url=url_to_dwnld, destfile=paste0('Annotation/TextGrids/', f_name, '.TextGrid'), quiet = T)
      }
    }
  }
}
