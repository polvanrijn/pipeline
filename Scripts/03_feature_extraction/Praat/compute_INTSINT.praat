select all
numberOfSelectedObjects = numberOfSelected ()
if numberOfSelectedObjects > 0
	Remove
endif


# Form with all setttings
form "Settings"
    sentence base_directory /Users/
endform

pt_directory$ = "'base_directory$'PitchTiers/02_estimated/"
file_pattern$ = "'pt_directory$'*.PitchTier"
tg_directory$ = "'base_directory$'/Annotation/INTSINT/"
createDirectory ("'tg_directory$'")

Create Strings as file list... list 'file_pattern$'
numberOfFiles = Get number of strings

for i from 1 to numberOfFiles
	select Strings list
    current_file$ = Get string... i
    Read from file... 'pt_directory$''current_file$'
    Stylize: 4, "Semitones"
    label$ = selected$ ("PitchTier")

	# Code targets
	execute "~/Library/Preferences/Praat Prefs/plugin_momel-intsint/analysis/code_with_intsint.praat"

	select TextGrid 'label$'
	Write to text file... 'tg_directory$''label$'.TextGrid

    select all
	minus Strings list
	Remove
endfor