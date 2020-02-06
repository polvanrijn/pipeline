setwd("~/Downloads/")

library(rvest)

page = read_html('corrected.html')
items = page %>%
  html_nodes(".item") %>%
  html_text()

items = gsub("[\r\n]", "", items)
items = gsub("    ", "", items)
df = NULL
for (item in items){
  if (grepl("Emotions:", item) & grepl("Elicitation:", item) & grepl("Size:", item)){
    end_lang = str_locate(item, ":")[1]
    language = str_sub(item, 1, end_lang - 1)
    item = str_sub(item, end_lang + 1)
    start_emo = str_locate(item, "Emotions:")
    description = str_sub(item, 1, start_emo[1] - 1)
    # TODO grab reference
    item = str_sub(item, start_emo[2] + 1)
    start_elicitation = str_locate(item, "Elicitation:")
    
    emotions = str_sub(item, 1, start_elicitation[1] - 1)
    item = str_sub(item, start_elicitation[2] + 1)
    start_size = str_locate(item, "Size:")
    
    elicitation = str_sub(item, 1, start_size[1] - 1)
    size = str_sub(item, start_size[2] + 1)
    
    if (!grepl("by",description)){
      if (nrow(str_locate_all(description, "\\(")[[1]]) != 1){
        warning(paste('Does not contain by', description))
        reference = ''
      } else {
        reference = str_sub(description, str_locate(description, "\\(")[1] + 1, str_locate(description, "\\)")[1] - 1)
      }
    } else{
      reference = str_sub(description, str_locate(description, "by")[2] + 2)
    }
    
    df = rbind(df, data.frame(
      language = language,
      description = description,
      reference = reference,
      emotions = emotions,
      elicitation = elicitation,
      size = size
      ))
  } else{
    stop("This may not happen!")
  }
}

