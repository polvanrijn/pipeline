select all
numberOfSelectedObjects = numberOfSelected ()
if numberOfSelectedObjects > 0
	Remove
endif


# Form with all setttings
form "Settings"
    sentence base_directory /Users/pol.van-rijn/MPI/02_running_projects/02_PhD/Papers/dynamic_features/Corpora/PELL/
endform

pt_base_directory$ = "'base_directory$'PitchTiers/"
csv_path$ = "'pt_base_directory$'pitch_settings.csv"
pt_directory$ = "'pt_base_directory$'02_estimated/"
createDirectory ("'pt_directory$'")
audio_directory$ = "'base_directory$'Audio/"


table = Read Table from tab-separated file: "'csv_path$'"

rows = Get number of rows

for row from 1 to rows
     key$ = Get value: row, "key"
     floors[key$]  = Get value: row, "floor"
     ceilings[key$]  = Get value: row, "ceiling"
endfor


Create Strings as file list... list 'audio_directory$'*.wav
number_of_files = Get number of strings
select Strings list
Sort

for x from 1 to number_of_files
    select Strings list
    current_file$ = Get string... x

    Read from file... 'audio_directory$''current_file$'

    sound_label$ = selected$ ("Sound")
    key$ = left$ (sound_label$, 6)

	
    pitch_floor = floors[key$]
    pitch_ceiling = ceilings[key$]
    appendInfo: key$, pitch_floor, pitch_ceiling, newline$
    

    Filter (pass Hann band)... pitch_floor 16000 40

    To Pitch... 0 pitch_floor pitch_ceiling
	Down to PitchTier
	Write to text file... 'pt_directory$''sound_label$'.PitchTier

	select all
	minus Strings list
	minus table
	Remove
endfor