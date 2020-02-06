library(rPraat)
library(stringr)
library(dplyr)
library(contouR)
library(ggplot2)
path = paste0( Sys.getenv("PT_DIR"), "Corpora/")
plot_folder = paste0( Sys.getenv("PT_DIR"), "Results/01_F0_densities_by_speaker/")

gender_per_corpus = list(
  'CREMA-D' = list(
    'males' = c('AA', 'AE', 'AK', 'AN', 'AO', 'AP', 'AQ', 'AS', 'AV', 'AW', 'AZ', 'BA', 'BE', 'BF', 'BG', 'BH', 'BI', 'BJ', 'BL', 'BM', 'BN', 'BO', 'BP', 'BR', 'BS', 'BV', 'BX', 'BY', 'CE', 'CG', 'CJ', 'CL','CM', 'CN', 'CO', 'CP', 'CQ', 'CR', 'CS', 'CY', 'DB', 'DC', 'DE', 'DG', 'DH', 'DI', 'DJ', 'DL'),
    'females' = c('AB', 'AC', 'AD', 'AF', 'AG', 'AH', 'AI', 'AJ', 'AL', 'AM', 'AR', 'AT', 'AU', 'AX', 'AY', 'BB', 'BC', 'BD', 'BK', 'BQ', 'BT', 'BU', 'BW', 'BZ', 'CA', 'CB', 'CC', 'CD', 'CF', 'CH', 'CI', 'CK', 'CT', 'CU', 'CV', 'CW', 'CX', 'CZ', 'DA', 'DD', 'DF', 'DK', 'DM')
  ),
  'PELL' = list(
    'males' = c('DF', 'MG'),
    'females' = c('NA', 'SL')
  ),
  'RAVDESS' = list(
    'males' = c('AA', 'CC', 'EE', 'GG', 'II', 'KK', 'MM', 'OO', 'QQ', 'SS', 'UU', 'WW'),
    'females' = c('BB', 'DD', 'FF', 'HH', 'JJ', 'LL', 'NN', 'PP', 'RR', 'TT', 'VV', 'XX')
  ),
  'SAVEE' = list(
    'males' = c('DC', 'JE', 'JK', 'KL'),
    'females' = c()
  ),
  'TESS' = list(
    'males' = c(),
    'females' = c('OA', 'YA')
  )
)

corpora = c('PELL','CREMA-D', 'RAVDESS', 'SAVEE', 'TESS')
all_estimates = NULL
for (corpus in corpora){
  all_sp = NULL
  pt_dir = paste0(path, corpus, "/PitchTiers/01_wide")
  setwd(pt_dir)
  files = list.files(pt_dir)
  files = files[grep('.PitchTier', files)]
  speakers = str_split_fixed(files, "_", 2)[,1]
  data_df = data.frame(file = files, speaker = speakers)
  unique_sp = unique(speakers)
  total_sp = length(unique_sp)
  pb = txtProgressBar()
  sp_count = 0
  for (sp in unique_sp){
    sp_count = sp_count + 1
    all_F0 = c()
    for (fn in filter(data_df, speaker == sp)$file){
      pt = read_PitchTier(paste0(pt_dir, "/", fn))
      all_F0 = c(all_F0, hqmisc::f2st(pt$f))
    }
    all_sp = rbind(all_sp, data.frame(
      speaker = sp,
      f = all_F0
    ))
    setTxtProgressBar(pb, sp_count/total_sp)
  }
  close(pb)
  ggplot(all_sp) +
    geom_density(aes(x = f)) +
    facet_wrap(~ speaker) +
    ggtitle("Speaker F0 density")
  ggsave(paste0(plot_folder, "density_by_speaker_", corpus, ".pdf"))

  estimate = as.data.frame(all_sp %>% group_by(speaker) %>% summarise(floor = quantile(f, c(.05)), ceiling = quantile(f, c(.95))))
  estimate$corpus = corpus

  estimate$gender = unlist(
    lapply(estimate$speaker, function(x){
      if (x %in% gender_per_corpus[[corpus]]$males){
        return("M")
      } else{
        return("F")
      }
    })
  )

  all_estimates = rbind(all_estimates, estimate)
}

ggplot(all_estimates) +
  geom_density(aes(x = floor, fill = gender), alpha = 0.6) +
  facet_wrap(~ corpus)

ggplot(all_estimates) +
  geom_density(aes(x = ceiling, fill = gender), alpha = 0.6) +
  facet_wrap(~ corpus)

ggplot(all_estimates) +
  geom_density(aes(x = floor), fill = "red", alpha = 0.6) +
  geom_density(aes(x = ceiling), fill = "blue", alpha = 0.6)

all_estimates$diff = all_estimates$ceiling - all_estimates$floor

ggplot(all_estimates) +
  geom_density(aes(x = diff, fill = gender), alpha = 0.6) +
  facet_wrap(~ corpus)

all_estimates %>% group_by(corpus, gender) %>% summarise(min(floor))

write.csv(all_estimates, paste0(plot_folder, "all_estimates.csv"))

# TODO Make a decision on which general floor to take per gender
# for (corpus in corpora){
#
# }

