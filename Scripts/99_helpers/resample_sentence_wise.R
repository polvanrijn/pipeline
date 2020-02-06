is_null_arr = function(var_list){
  bool_list = c()
  for (l in var_list) {
    bool_list = c(bool_list, is.null(l))
  }
  return(all(bool_list))
}

get_voiced_limits_per_word = function(labels, label_idx, pt, tier, filename){
  t1 = c()
  t2 = c()
  pitch_point = list()
  times = list()
  i = 0
  for (word_idx in label_idx) {
    i = i + 1
    # Get the word boundaries
    w_bound_start = tier$t1[word_idx]
    w_bound_end = tier$t2[word_idx]

    # Which PitchPoints lay in this area?
    pt_idx_in_w = which(pt$t >= w_bound_start & pt$t < w_bound_end)

    if (length(pt_idx_in_w) == 0) {
      print(paste("Empty word", filename, labels[i]))
      t1 = c(t1, NA)
      t2 = c(t2, NA)
      pitch_point[[i]] = NA
      times[[i]] = NA
    } else {
      t1 = c(t1, pt$t[min(pt_idx_in_w)])
      t2 = c(t2, pt$t[max(pt_idx_in_w)])
      pitch_point[[i]] = pt$f[pt_idx_in_w]
      times[[i]] = pt$t[pt_idx_in_w]
    }

  }
  return(list(t1 = t1, t2 = t2, pitch_point = pitch_point, times = times))
}

grab_and_squeeze = function(filename, pt_path, tg_path, sentence_wide_df, frame_length, tier_name, NEU_t1 = NULL, NEU_t2 = NULL){
  print(filename)
  pt_file_path = paste0(pt_path, filename, ".PitchTier")
  tg_file_path = paste0(tg_path, filename, ".TextGrid")
  pt = contouR::read_PitchTier(pt_file_path)

  if (!round(frame_length,5) %in% round(diff(pt$t), 5)) {
    stop('The supplied frame length does not fit the data!')
  }
  tg = contouR::read_TextGrid(tg_file_path)
  word_tier = tg[[tier_name]]
  label_idx = which(word_tier$label != "")
  labels = word_tier$label[label_idx]

  if (is_null_arr(list(NEU_t1, NEU_t2))) {
    is_NEU = TRUE

    temp = get_voiced_limits_per_word(labels, label_idx, pt, word_tier, filename)
    NEU_t1 = temp$t1
    NEU_t2 = temp$t2

    t = pt$t
    f = pt$f

    tmin = head(NEU_t1,1)
    tmax = tail(NEU_t2,1)
    compression = 0
  } else{
    is_NEU = TRUE
    if (!all(c(length(NEU_t1) == length(label_idx), length(NEU_t2) == length(label_idx)))) {
      stop('Number of labels must match!!')
    }

    temp = get_voiced_limits_per_word(labels, label_idx, pt, word_tier, filename)
    EMO_t1 = temp$t1
    EMO_t2 = temp$t2

    ref_dur = NEU_t2 - NEU_t1
    cur_dur = EMO_t2 - EMO_t1
    t = c()
    f = c()

    for (i in 1:length(EMO_t1)) {
      # if (!(any(is.na(temp$times[[i]])) & any(is.na(temp$times[[i]])))) {
      if (!is.na(NEU_t1[i])) {
        scalar = ref_dur[i]/cur_dur[i]
        # First make it start at 0, then multiply this with a scalar, finally add the neutral
        t_temp = (temp$times[[i]] - EMO_t1[i])*scalar + NEU_t1[i]

        if (length(temp$pitch_point[[i]]) > 2) {
          # Resample here
          interpol = approxfun(t_temp, temp$pitch_point[[i]])
          resamp_t = seq(from = NEU_t1[i], to = NEU_t2[i], by = frame_length)
          resamp_f = interpol(resamp_t)

          t = c(t, resamp_t)
          f = c(f, resamp_f)
        } else {
          t = c(t, t_temp)
          f = c(f, temp$pitch_point[[i]])
        }
      }
    }

    tmin = head(NEU_t1,1)
    tmax = tail(NEU_t2,1)
    compression = (max(pt$t) - min(pt$t))/(tmax - tmin)
  }

  has_NAs = FALSE

  if (is.na(tmin) | is.na(tmax)) {
    has_NAs = TRUE
  } else {
    interpol = approxfun(t, f)
    resamp_t = seq(from = tmin, to = tmax, by = frame_length)
    resamp_f = interpol(resamp_t)

    splt_name = strsplit(filename, "_")[[1]]


    NA_idxs = which(is.na(resamp_f))

    if (length(NA_idxs) == 1) {
      if (NA_idxs == length(resamp_f)) {
        # A common artifact in interpolation is that the last point will turn into a NA
        # We can replace a single NA at the end with last valid pitch value
        resamp_f[length(resamp_f)] = tail(f, 1)
      } else {
        has_NAs = TRUE
      }
    } else if (length(NA_idxs) > 1) {
      has_NAs = TRUE
    }
  }

  if (has_NAs) {
    warning(filename, "does not contain pitch for some words; this file is excluded")
  } else{

    sentence_wide_df = rbind(sentence_wide_df, data.frame(
      t = resamp_t,
      f = resamp_f,
      speaker = splt_name[1],
      emotion = splt_name[2],
      sentence = splt_name[3],
      intensity = splt_name[4],
      repetition = splt_name[5],
      compression = compression,
      filename = filename
    ))
  }


  if (is_NEU) {
    return(list(
      sentence_wide_df = sentence_wide_df,
      NEU_t1 = NEU_t1,
      NEU_t2 = NEU_t2
    ))
  } else{
    return(sentence_wide_df)
  }
}

resample_sentence_wise = function(path, corpus, pt_dir_name, tg_dir_name, pitch_settings_csv_path = NULL, tier_name = 'words'){
  library(dplyr)
  sentence_wide_df = NULL
  wd = paste0(path, corpus, "/")

  # Set the right paths
  pt_path = paste0(wd, "PitchTiers/", pt_dir_name, "/")
  tg_path = paste0(wd, "Annotation/", tg_dir_name, "/")

  # Make sure all PTs have a csv version
  cache_pts(pt_path)

  # Load the file df, with all files that are being processed
  file_df = read.csv(paste0(wd, "file_df.csv"), colClasses = "character")
  file_df$speaker[is.na(file_df$speaker)] = "NA"
  if (is.null(pitch_settings_csv_path)) {
    pitch_settings_csv_path = paste0(wd, "PitchTiers/pitch_settings.csv")
  }
  pitch_settings = read.table(pitch_settings_csv_path, header = T, colClasses = c(rep("character", 2), rep("numeric", 2), rep("character", 2)))
  pitch_settings$speaker[is.na(pitch_settings$speaker)] = "NA"


  # Normally this is one, except for one corpus where there are two recordings of each stimulus
  repetitions = unique(filter(file_df, emotion == "NEU")$repetition)
  #emotions = unique(file_df$emotion)
  #not_NEU_emotions = emotions[emotions != "NEU"]
  for (speaker_glob in unique(file_df$speaker)) {
    frame_length = 0.75/filter(pitch_settings, speaker == speaker_glob)$floor[1]
    for (sentence_glob in unique(file_df$sentence)) {
      for (repetition_glob in repetitions) {
        # Grab your neutral version
        NEU_filename = filter(file_df, speaker == speaker_glob, sentence == sentence_glob, emotion == "NEU", repetition == repetition_glob)$new_name
        if (length(NEU_filename) != 1) {
          stop("Only one file allowed")
        }

        temp = grab_and_squeeze(NEU_filename, pt_path, tg_path, sentence_wide_df, frame_length, tier_name)

        NEU_t1 = temp$NEU_t1
        NEU_t2 = temp$NEU_t2

        # Grab your emotional version
        if (length(repetitions) == 1 & repetitions[1] == 1) {
          EMO_filenames = filter(file_df, speaker == speaker_glob, sentence == sentence_glob, new_name != NEU_filename)$new_name
        } else{
          EMO_filenames = filter(file_df, speaker == speaker_glob, sentence == sentence_glob, repetition == repetition_glob, new_name != NEU_filename)$new_name
        }

        safe_to_continue = TRUE

        if (any(c(is.na(NEU_t1), is.na(NEU_t2)))) {
          # A word is missing in the neutral condition; impossible to realign emotional to neutral
          safe_to_continue = FALSE
        } else if (length(which((NEU_t2 - NEU_t1) == 0)) > 0) {
          # At a given word in the neutral condition there was only one pitch point, i.e. duration is tmax - tmin, but since tmax = tmin, the duration is 0, which causes the problem
          safe_to_continue = FALSE
        }


        if (safe_to_continue) {
          sentence_wide_df = temp$sentence_wide_df

          for (EMO_filename in EMO_filenames) {
            temp = grab_and_squeeze(EMO_filename, pt_path, tg_path, sentence_wide_df, frame_length, tier_name, NEU_t1, NEU_t2)
            sentence_wide_df = temp$sentence_wide_df
          }
        } else {
          for (EMO_filename in EMO_filenames) {
            warning(EMO_filename, "does not contain pitch for some words; this file is excluded")
          }
        }
      }
    }
  }

  return(sentence_wide_df)
}


naive_grab_and_squeeze = function(filename, pt_path, naive_sentence_wide_df, frame_length, tmin = NULL, tmax = NULL) {
  print(filename)
  pt_file_path = paste0(pt_path, filename, ".PitchTier")
  pt = contouR::read_PitchTier(pt_file_path)

  if (!round(frame_length,5) %in% round(diff(pt$t), 5)) {
    stop('The supplied frame length does not fit the data!')
  }
  safe_to_continue = TRUE

  if (is_null_arr(list(tmax, tmin))) {
    is_NEU = TRUE

    tmin = min(pt$t)
    tmax = max(pt$t)
    t_temp = pt$t
    compression = 0
  } else {
    is_NEU = FALSE
    scalar = (tmax - tmin)/(max(pt$t) - min(pt$t))
    # First make it start at 0, then multiply this with a scalar, finally add the neutral
    t_temp = (pt$t - min(pt$t))*scalar + tmin
    compression = (max(pt$t) - min(pt$t))/(tmax - tmin)
  }

  if (length(pt$t) < 3) {
    # Sentence does not contain enought pitch points
    safe_to_continue = FALSE
    warning("Sentence", filename, "does not contain enough pitch points (<=2)")
  } else if (is.na(tmin) | is.na(tmax)) {
    safe_to_continue = FALSE
    warning("Sentence", filename, "does not contain pitch points")
  }

  if (safe_to_continue) {
    interpol = approxfun(t_temp, pt$f)
    resamp_t = seq(from = tmin, to = tmax, by = frame_length)
    resamp_f = interpol(resamp_t)

    if (is.na(resamp_f[length(resamp_f)])){
      # Fix interpolate bug
      resamp_f[length(resamp_f)] = resamp_f[length(resamp_f) - 1]
    }

    if (any(is.na(resamp_f))) {
      warning(paste(filename, "contains NAs"))
      safe_to_continue = FALSE
    } else {
      splt_name = strsplit(filename, "_")[[1]]

      naive_sentence_wide_df = rbind(naive_sentence_wide_df, data.frame(
        t = resamp_t,
        f = resamp_f,
        speaker = splt_name[1],
        emotion = splt_name[2],
        sentence = splt_name[3],
        intensity = splt_name[4],
        repetition = splt_name[5],
        compression = compression,
        filename = filename
      ))
    }
  }

  return(list(naive_sentence_wide_df = naive_sentence_wide_df, tmax = tmax, tmin = tmin, safe_to_continue = safe_to_continue))
}

naive_resample_sentence_wise = function(path, corpus, pt_dir_name, pitch_settings_csv_path = NULL){
  library(dplyr)
  naive_sentence_wide_df = NULL
  wd = paste0(path, corpus, "/")

  # Set the right paths
  pt_path = paste0(wd, "PitchTiers/", pt_dir_name, "/")

  # Make sure all PTs have a csv version
  cache_pts(pt_path)

  # Load the file df, with all files that are being processed
  file_df = read.csv(paste0(wd, "file_df.csv"), colClasses = "character")
  file_df$speaker[is.na(file_df$speaker)] = "NA"
  if (is.null(pitch_settings_csv_path)) {
    pitch_settings_csv_path = paste0(wd, "PitchTiers/pitch_settings.csv")
  }
  pitch_settings = read.table(pitch_settings_csv_path, header = T, colClasses = c(rep("character", 2), rep("numeric", 2), rep("character", 2)))
  pitch_settings$speaker[is.na(pitch_settings$speaker)] = "NA"

  # Normally this is one, except for one corpus where there are two recordings of each stimulus
  repetitions = unique(filter(file_df, emotion == "NEU")$repetition)
  for (speaker_glob in unique(file_df$speaker)) {
    frame_length = 0.75/filter(pitch_settings, speaker == speaker_glob)$floor[1]
    for (sentence_glob in unique(file_df$sentence)) {
      for (repetition_glob in repetitions) {
        # Grab your neutral version
        NEU_filename = filter(file_df, speaker == speaker_glob, sentence == sentence_glob, emotion == "NEU", repetition == repetition_glob)$new_name
        if (length(NEU_filename) == 0){
          warning("File is missing for:", speaker_glob, sentence_glob, "NEU", repetition_glob)
        } else {
          if (length(NEU_filename) != 1) {
            stop("Only one file allowed")
          }

          # Grab your emotional version
          if (length(repetitions) == 1 & repetitions[1] == 1) {
            EMO_filenames = filter(file_df, speaker == speaker_glob, sentence == sentence_glob, new_name != NEU_filename)$new_name
          } else{
            EMO_filenames = filter(file_df, speaker == speaker_glob, sentence == sentence_glob, repetition == repetition_glob, new_name != NEU_filename)$new_name
          }

          temp = naive_grab_and_squeeze(NEU_filename, pt_path, naive_sentence_wide_df, frame_length)
          safe_to_continue = temp$safe_to_continue

          if (safe_to_continue) {
            naive_sentence_wide_df = temp$naive_sentence_wide_df
            tmin = temp$tmin
            tmax = temp$tmax

            for (EMO_filename in EMO_filenames) {
              temp = naive_grab_and_squeeze(EMO_filename, pt_path, naive_sentence_wide_df, frame_length, tmin, tmax)

              if (temp$safe_to_continue){
                naive_sentence_wide_df = temp$naive_sentence_wide_df
              } else {
                warning(EMO_filename, "does not contain pitch for some words; this file is excluded")
              }
            }
          } else {
            warning(NEU_filename, "does not contain pitch for some words; this file is excluded")
            for (EMO_filename in EMO_filenames) {
              warning(EMO_filename, "does not contain pitch for some words; this file is excluded")
            }
          }
        }
      }
    }
  }

  return(naive_sentence_wide_df)
}

#sentence_wide_df_naive = naive_resample_sentence_wise(path, corpus, '02_estimated')
