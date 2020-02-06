get_gender_for_corpus = function(){
  return(
    list(
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
  )
}
