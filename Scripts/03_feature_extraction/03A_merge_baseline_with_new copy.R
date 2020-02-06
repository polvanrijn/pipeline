read_corpus_csv = function(name){
  return(read.csv(paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Features/", name, ".csv")))
}

rename_name_to_filename = function(df){
  if (!"name" %in% names(df)){
    stop("The df does not contain the name 'name'")
  }
  col_idx = which(names(df) == "name")
  names(df)[col_idx] = "filename"
  df$filename = stringr::str_remove(df$filename, ".csv")
  return(df)
}




corpora = c('PELL', 'CREMA-D', 'RAVDESS', 'SAVEE', 'TESS')
for (corpus in corpora) {

  features = read_corpus_csv('morphometric')
  
  frequency = read_corpus_csv('frequency')
  frequency = frequency[c("filename", "max_rows", "t_max_rows",  "max_rows_st", "t_max_rows_st")]
  names(frequency) = c("filename", "peak_frequency", "peak_amplitude", "st_peak_frequency", "st_peak_amplitude")
  features = contouR::combine_features(features, frequency, "filename")

  minimal_harmonics = read_corpus_csv('minimal_harmonics')
  minimal_harmonics = minimal_harmonics[names(minimal_harmonics) != "max_freq"]
  features = contouR::combine_features(features, minimal_harmonics, "filename")

  INTSINT_MOMEL = read_corpus_csv('INTSINT_MOMEL')
  features = contouR::combine_features(features, INTSINT_MOMEL, "filename")

  accent = read_corpus_csv('accent')[-1] # remove column 'name'
  features = contouR::combine_features(features, accent, "filename")

  slopes = read_corpus_csv('slopes')
  slopes = rename_name_to_filename(slopes)
  slopes = slopes[c("filename", "a", "b", "naive_intercept", "naive_slope", "min_max_slope")]
  features = contouR::combine_features(features, slopes, "filename")

  phrase = read_corpus_csv('phrase')
  phrase = rename_name_to_filename(phrase)
  phrase = phrase[c("filename", "num_phrases", "Ap")]
  features = contouR::combine_features(features, phrase, "filename")

  ICCs = read_corpus_csv('ICCs')
  ICCs = rename_name_to_filename(ICCs)
  ICCs = ICCs[c("filename", "num_ICCs", "num_pos_ICCs", "num_neg_ICCs", "mean_delta_F0", "sd_delta_F0", "mean_delta_tc", "sd_delta_tc")]
  features = contouR::combine_features(features, ICCs, "filename")

  eGeMAPS = read_corpus_csv('eGeMAPS')
  col_order_idx = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 31, 32, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 33, 34, 35, 36, 88, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 37, 38, 39, 40, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, which(names(eGeMAPS)== "filename"))
  eGeMAPS = eGeMAPS[col_order_idx]
  features = contouR::combine_features(eGeMAPS, features, "filename")
  # Add eGeMAPS
  write.csv(features, paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Features/combined_features.csv"), row.names = F)
}
