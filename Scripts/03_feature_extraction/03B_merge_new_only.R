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




corpora = c("PELL_SCRAM", "PELL_MAN")
for (corpus in corpora) {

  features = read_corpus_csv('morphometric')
  frequency = read_corpus_csv('frequency')
  frequency = frequency[c("filename", "compression", "max_rows", "t_max_rows", "compression_st",  "max_rows_st", "t_max_rows_st")]

  # st_compression_rate is a duplicate of compression_rate
  names(frequency) = c("filename", "compression_rate", "peak_frequency", "peak_amplitude", "st_compression_rate", "st_peak_frequency", "st_peak_amplitude")

  features = contouR::combine_features(features, frequency, "filename")

  minimal_harmonics = read_corpus_csv('minimal_harmonics')
  features = contouR::combine_features(features, minimal_harmonics, "filename")

  #INTSINT_MOMEL = read_corpus_csv('INTSINT_MOMEL')
  #features = contouR::combine_features(features, INTSINT_MOMEL, "filename")

  accent = read_corpus_csv('accent')[-1] # remove column 'name'
  features = contouR::combine_features(features, accent, "filename")

  slopes = read_corpus_csv('slopes')
  slopes = slopes[!grepl(".csv", slopes$name), ]
  
  slopes = rename_name_to_filename(slopes)
  slopes = slopes[c("filename", "a", "b", "naive_intercept", "naive_slope", "min_max_slope")]
  features = contouR::combine_features(features, slopes, "filename")

  phrase = read_corpus_csv('phrase')
  phrase = rename_name_to_filename(phrase)
  phrase = phrase[c("filename", "num_phrases", "Ap")]
  features = contouR::combine_features(features, phrase, "filename")

  ICCs = read_corpus_csv('ICCs')
  ICCs = rename_name_to_filename(ICCs)
  ICCs = ICCs[c("filename", "num_ICCs", "num_pos_ICCs", "num_neg_ICCs", "mean_delta_F0", "sd_delta_F0", "mean_tc", "sd_tc", "mean_delta_tc", "sd_delta_tc")]
  features = contouR::combine_features(features, ICCs, "filename")

  #distribution = read_corpus_csv('distribution_features')
  #distribution = rename_name_to_filename(distribution)
  #distribution = distribution[1:4]
  #features = contouR::combine_features(features, distribution, "filename")

  write.csv(features, paste0(Sys.getenv("PT_DIR"), "Corpora/", corpus, "/Features/dynamic_features.csv"), row.names = F)
}
