download_webmaus = function(f_name, filenames = NULL, check_missing_files = TRUE){
  if (check_missing_files){
    if (file.exists('missing_files.csv')){
      missing_files = read.csv('missing_files.csv')
    } else {
      missing_files = NULL
    }
    downloadable = (!f_name %in% missing_files$f_name)
  } else {
    downloadable = TRUE
  }
  
  tg_already_exist = FALSE
  if (!is.null(filenames)){
    tg_already_exist = !paste0(f_name, '.TextGrid') %in% filenames
  }
  
  
  if (!tg_already_exist && downloadable){
    api_URL = 'https://clarin.phonetik.uni-muenchen.de/BASWebServices/services/runMAUSBasic'
    language_param = 'LANGUAGE=deu'
    text_param = paste0('TEXT=@Annotation/Sentences/', f_name, '.txt')
    signal_param = paste0('SIGNAL=@Audio/', f_name, '.wav')
    cmd = paste("curl --silent -X POST -H 'content-type: multipart/form-data'", "v=1 -F", language_param, "-F OUTSYMBOL=ipa -F",  text_param, '-F', signal_param,  api_URL)
    url_to_dwnld = extract_url(sys_call(cmd))
    
    if (url_to_dwnld == ""){
      warning(paste("Could not download", f_name, corpus))
      if (check_missing_files){
        missing_files = rbind(missing_files, data.frame(
          f_name = f_name,
          corpus = corpus,
          type = "TextGrid"
        ))
        write.csv(missing_files, 'missing_files.csv', row.names = F)
      }
    } else {
      print(paste("Download:", f_name))
      download.file(url=url_to_dwnld, destfile=paste0('Annotation/TextGrids/', f_name, '.TextGrid'), quiet = T)
    }
  }
}

sys_call = function(cmd){
  return(system(paste("cd", getwd(), "&&", cmd), intern = TRUE))
}

extract_url = function(response){
  library('rvest')
  return(read_html(response) %>%
           html_nodes(xpath='//downloadlink') %>%
           html_text())
}