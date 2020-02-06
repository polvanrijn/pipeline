# Read me

This folder contains all steps to come from the raw sound files to the classification.

- `00_universalise_files` contains scripts to rename filenames of sounds in different corpora, so they all have the same structure
- `01_WebMaus` aligns the transcript with the audio using the webservice of *Webmaus*. The TextGrids are saved in the corpora.
- `02_pitch_tracking` performs a step-wise algorithm to estimate the optimal pitch floor. Ceilings are approximated per speaker $\times$ emotion group; this requires the program *Praat* to be installed. Also, Fujisaki parameters are estimated.
- `03_feature_extraction` computes all features and merges them into one big file per corpus. This step depends on *OpenSMILE* to compute the baseline features and *Praat* to compute other features. Feature computation is devided in local operations  and operations on the HPC. If you don't have access to a HPC you'll have to modify them
- `04_classification` performs the classification on the feature sets (SVM) and computes the feature importance. 
- `99_helpers` contains some helpers