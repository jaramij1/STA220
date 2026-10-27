# scripts/master.R
# Rebuilds everything from the raw files in data/raw/: the tables 02_import.R writes, every figure
# in output/figures/, and the Task 6 chart in output/. Restart R first (Session > Restart R), then
# source this file from the project.
# 01_setup.R is not here: run it once by hand.
# 14_practice_in_r.R is not here either: that one is for you to fill in.

source("scripts/02_import.R")

source("scripts/03_know_your_key.R")          # Section 1: Know your key            (no figure)

source("scripts/04_one_variable.R")           # Section 2: One variable             (Figures 2 to 7)

source("scripts/05_two_variables.R")          # Section 3: Two variables            (Figures 8 to 13)

source("scripts/06_three_or_more.R")          # Section 4: Three or more variables  (Figures 14 to 18)

source("scripts/07_fixing_keys.R")            # Section 6: Two sources, one graphic (no figure)

source("scripts/08_can_these_be_merged.R")    #                                     (no figure)

source("scripts/09_the_merge.R")              #                                     (Figure 19)

source("scripts/10_rates_from_two_sources.R") #                                     (Figures 20 and 21)

source("scripts/11_same_unit.R")              #                                     (no figure)

source("scripts/12_reporting_a_merge.R")      #                                     (Figure 22)

source("scripts/13_module_practice.R")        # Module 3.2 Practice                 (Figures 23 and 24)

source("scripts/15_practice_solutions.R")     # Practice in R, one way to do each task

list.files("output/figures")
