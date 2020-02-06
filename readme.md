# Read me

In order to replicate the findings you'll need the following things:

1. Get access to all of the corpora.
2. Create a folder `Corpora` and add each corpus to the folder as a subfolder, e.g. `Corpora/CREMA-D`
3. Move the audio from the corpus to `Corpora/<CORPUS>/Audio`

(if you add a new corpus, you need to write a rename script, see examples in `Scripts/00_universalise_files`)

Please make sure you have the packages [`contouR`](https://github.com/polvanrijn/contouR) and [`hpcR`](https://github.com/polvanrijn/hpcR) installed (e.g. `devtools::install_github("polvanrijn/contouR")`). These packages will allow you to do the operations on the contours and communicate with a HPC (if you have access to one). If you do not have access to a HPC, you'll need to slightly adapt the scripts in `Scripts/03_feature_extraction` and `Scripts/04_classification`. Also, in order to extract the Fujisaki parameters, you either need to run R on Windows or have a virtual machine running Windows in the background (if you have any questions, feel free to contact me).



The pipeline requires you to set following global parameters: `PT_DIR` which is the working directory (the folder where this README file is in) and `CORPORA` which specifies which corpora are used.

You can change it by running `file.edit(path.expand(file.path("~", ".Renviron")))` in the RStudio console. This will open up your environment file. You may add or modify a variable, e.g. the line that defines `CORPORA` looks like this:

```R
CORPORA=PELL_SCRAM,PELL_MAN
```



If you have any questions, feel free to contact me.