select all
numberOfSelectedObjects = numberOfSelected ()
if numberOfSelectedObjects > 0
	Remove
endif


# Form with all setttings
form "Settings"
    sentence base_directory /Users/
endform

pt_base_directory$ = "'base_directory$'PitchTiers/"
csv_path$ = "'pt_base_directory$'gender_df.csv"
createDirectory ("'pt_base_directory$'")
hirst_directory$ = "'pt_base_directory$'hirst2011/"
createDirectory ("'hirst_directory$'")
delooze_directory$ = "'pt_base_directory$'delooze2010/"
createDirectory ("'delooze_directory$'")
audio_directory$ = "'base_directory$'Audio/"

procedure minmaxf0 (minF0, maxF0)
	selsnd_m = selected("Sound")
	nocheck noprogress To Pitch... 0 minF0 maxF0
	fullName$ = selected$()
	type$ = extractWord$(fullName$, "")
	if type$ = "Pitch"
		voicedframes = Count voiced frames
		if voicedframes > 0
			q25 = Get quantile... 0 0 0.25 Hertz
			q75 = Get quantile... 0 0 0.75 Hertz
			minF0 = round(q25 * 0.75)
			maxF0 = round(q75 * 1.5)
		endif
		Remove
	endif
	select selsnd_m
endproc

Create Strings as file list... list 'audio_directory$'*.wav
number_of_files = Get number of strings
select Strings list
Sort

for x from 1 to number_of_files
    select Strings list
    current_file$ = Get string... x
	
	sound = Read from file... 'audio_directory$''current_file$'

	sound_label$ = selected$ ("Sound")
	Filter (pass Hann band)... 50 16000 100
	
	# Hirst 2011
	@minmaxf0(50, 700)
	select sound
	To Pitch... 0 minF0 maxF0
	Down to PitchTier
	Write to text file... 'hirst_directory$''sound_label$'.PitchTier

	select sound
	@minmaxf0(60, 750)
	select sound
	To Pitch... 0 minF0 maxF0
	Down to PitchTier
	Write to text file... 'delooze_directory$''sound_label$'.PitchTier

	select all
	minus Strings list
	Remove
endfor