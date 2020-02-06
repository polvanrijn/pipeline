number_to_two_letters = function(numbers){
  prefix_letter = "A"
  result = c()
  for (numb in numbers){
    if (numb > 26){
      multiples_of_26 = floor((numb - 1)/26)
      prefix_letter = LETTERS[1 + multiples_of_26]
      numb = numb - 26 * multiples_of_26
    }
    result = c(result, paste0(prefix_letter, LETTERS[numb]))
  }
  
  return(result)
}
