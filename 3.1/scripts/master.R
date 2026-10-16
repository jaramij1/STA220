# scripts/master.R
# Rebuilds everything from data/UFB.xlsm: the tables in data/, every figure in output/figures/,
# and the Task 5 chart in output/. Restart R first (Session > Restart R), then source this file from the project.
# 01_setup.R is not here: run it once by hand, because it installs packages.
# 11_practice_in_r.R is not here either: that one is for you to fill in.
source("scripts/02_import.R")
source("scripts/03_know_your_rows.R")
source("scripts/04_how_a_graphic_is_built.R")
source("scripts/05_scales.R")
source("scripts/06_honest_axes.R")
source("scripts/07_what_the_eye_compares.R")
source("scripts/08_labels_and_description.R")
source("scripts/09_critique.R")
source("scripts/10_module_practice.R")
source("scripts/12_practice_solutions.R")
list.files("output/figures")
