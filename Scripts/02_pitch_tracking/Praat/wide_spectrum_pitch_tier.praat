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
pt_directory$ = "'pt_base_directory$'01_wide/"
createDirectory ("'pt_directory$'")
audio_directory$ = "'base_directory$'Audio/"

table = Read Table from tab-separated file: "'csv_path$'"

rows = Get number of rows

for row from 1 to rows
     key$ = Get value: row, "speakers"
     speakers$[key$]  = Get value: row, "gender"
endfor
pitch_ceiling = 1000
pitch_floor = 60

Create Strings as file list... list 'audio_directory$'*.wav
number_of_files = Get number of strings
select Strings list
Sort

for x from 1 to number_of_files
    select Strings list
    current_file$ = Get string... x
	
	Read from file... 'audio_directory$''current_file$'

	sound_label$ = selected$ ("Sound")
	key$ = left$ (sound_label$, 2)
	gender$ = speakers$[key$]
	#if (gender$ == "M")
	#	pitch_floor = 70
	#else
	#	pitch_floor = 120
	#endif
	
    Filter (pass Hann band)... pitch_floor 16000 100

	To Pitch... 0 pitch_floor pitch_ceiling
	Down to PitchTier
	Write to text file... 'pt_directory$''sound_label$'.PitchTier

	select all
	minus Strings list
	Remove
endfor