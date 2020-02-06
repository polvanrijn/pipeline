rename_files = function(path, extention, old_names, new_names){
  setwd(path)
  files = list.files('.')
  files = files[grepl(extention, files)]
  files = sort(files)
  
  new_names = paste0(new_names, extention)
  old_names = paste0(old_names, extention)
  rename_df = data.frame(new_name = new_names, old_name = old_names)
  rename_df = rename_df[order(rename_df$old_name), ]
  
  if (all(rename_df$old_name == files)){
    new_names = as.character(rename_df$new_name)
    file.rename(files, new_names)
  } else{
    idxs = which(rename_df$old_name != files)
    stop(paste(rename_df$old_name[idxs]))
  }
}