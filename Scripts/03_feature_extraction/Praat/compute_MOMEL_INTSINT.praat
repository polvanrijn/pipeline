select all
numberOfSelectedObjects = numberOfSelected ()
if numberOfSelectedObjects > 0
	Remove
endif

procedure minmaxf0
	# This script uses the automatic estimation of min and max f0 proposed by Daniel Hirst for the Momel project
	# https://www.researchgate.net/publication/228640428_A_Praat_plugin_for_Momel_and_INTSINT_with_improved_algorithms_for_modelling_and_coding_intonation
	selsnd_m = selected("Sound")
	nocheck noprogress To Pitch... 0 40 600
	fullName$ = selected$()
	type$ = extractWord$(fullName$, "")
	if type$ = "Pitch"
		voicedframes = Count voiced frames
		if voicedframes > 0
			q25 = Get quantile... 0 0 0.25 Hertz
			q75 = Get quantile... 0 0 0.75 Hertz
			minF0 = round(q25 * 0.75)
			maxF0 = round(q75 * 1.5)
		else
			minF0 = 40
			maxF0 = 600
		endif
		Remove
	else
		minF0 = 40
		maxF0 = 600
	endif
	select selsnd_m
endproc


# Form with all setttings
form "Settings"
    sentence base_directory /Users/
endform

# Fixed Settings, just for now the recommended settings
audio_directory$ = "'base_directory$'Audio/"
file_pattern$ = "'audio_directory$'*.wav"
tg_directory$ = "'base_directory$'/Annotation/MOMEL_INTSINT/"
createDirectory ("'tg_directory$'")

Create Strings as file list... list 'file_pattern$'
numberOfFiles = Get number of strings

for i from 1 to numberOfFiles
	select Strings list
    current_file$ = Get string... i
    Read from file... 'audio_directory$''current_file$'
    duration = Get total duration
	sound_label$ = selected$ ("Sound")

	# Estimate Pitch like Hirst
	@minmaxf0
    
	# Create Pitch
	To Pitch... 0 minF0 maxF0

	# Simplify contour: detect MOMEL targets
	execute "~/Library/Preferences/Praat Prefs/plugin_momel-intsint/analysis/momel_single_file.praat" 30 60 750 1.04 20 5 0.05

	# Code targets
	execute "~/Library/Preferences/Praat Prefs/plugin_momel-intsint/analysis/code_with_intsint.praat"

	select TextGrid 'sound_label$'
	Write to text file... 'tg_directory$''sound_label$'.TextGrid
	
    select all
	minus Strings list
	Remove
endfor