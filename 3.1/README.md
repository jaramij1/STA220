# STA 220, Module 3.1: the example project

The R behind workbook 3.1 (Principles of Visualization): the tables on page 3, every figure, and
the Practice in R tasks. Data for Everyday Life, The College of New Jersey, fall 2026.

## For students

Clone this repository (clone, not fork), open `3.1.Rproj`, and work through `scripts/` in order:

1. `01_setup.R` is the setup check from the workbook. Run it once; it installs the packages
   Module 3 needs.
2. `02_import.R` reads the database and writes the small tables in `data/`. They are already
   there, so you only need to run it if you want to see how they were made.
3. `03` to `10` make the figures in the workbook, one script per section. Open any of them, run
   it a line at a time, change something, and run it again.
4. `11_practice_in_r.R` is yours to fill in: five tasks comparing New Jersey's college towns,
   one page of questions each in the workbook.
5. `12_practice_solutions.R` is one way to make each of the five figures. Try first.

## What is here

```
3.1/
  3.1.Rproj                    # double-click to open the project
  README.md                    # this file
  data/
    UFB.xlsm                   # the raw User Friendly Budget Database. Never edit by hand!
    mercer.csv                 # made by 02_import.R: the 12 Mercer County towns, budget year 2025
    ewing.csv                  # made by 02_import.R: Ewing township, 2021 to 2025
    colleges.csv               # made by 02_import.R: 13 college towns, budget year 2025
    glassboro.csv              # made by 02_import.R: Glassboro borough, 2016 to 2025
    nj_towns_2016_2025.csv     # made by 02_import.R: every NJ town in every year (for 3.3, and the state benchmark)
  scripts/
    01_setup.R                 # the setup check; installs the module's packages
    02_import.R                # reads the database, writes data/*.csv
    03_know_your_rows.R        # Figure 1
    04_how_a_graphic_is_built.R  # Figures 2, 3, 4
    05_scales.R                # Figure 5, the blank axis, the blank grid
    06_honest_axes.R           # Figures 6, 7
    07_what_the_eye_compares.R # Figure 8
    08_labels_and_description.R  # Figures 9, 10
    09_critique.R              # Figures 11, 12, and the state benchmark
    10_module_practice.R       # Figures 13, 14, the blank axes for the newsletter question
    11_practice_in_r.R         # Practice in R: five tasks for students to write
    12_practice_solutions.R    # one way to make each of the five figures
    master.R                   # source() 02 to 10 and 12, in order
  output/
    figures/                   # made by the scripts; rerun, don't edit
    budget_per_resident.png    # not in the repository: your Task 5 chart lands here
```

Each figure script needs only the tidyverse (plus `patchwork` for the side-by-side figures) and
the CSV files in `data/`. `02_import.R` also needs `readxl`, which comes with the tidyverse.

## The data

`data/UFB.xlsm` is the User Friendly Budget Database published by the New Jersey Department of
Community Affairs, Division of Local Government Services. One sheet per budget year, 2016 to 2026;
one row per municipality that filed a User Friendly Budget, plus Minimum, Maximum, Median, and
Average rows at the bottom. The figures are self-reported by the municipalities and, as the
database's own introduction says, have not been independently audited or verified. Population is
the Census Bureau estimate the database includes. Downloaded in fall 2026.

What the tables use, and where it comes from in a Summary sheet (subgroup header, then column name):

| column | sheet column |
|---|---|
| `pop` | Population and Density: Population (2024 Estimate) |
| `land_sqmi` | Population and Density: 2020 Land Area (sq. mi) |
| `budget_m` | 2025 General Budget Appropriations: Total General Budget, divided by 1,000,000 and rounded to one decimal |
| `state_aid_m` | 2025 Total Anticipated Revenues: State Aid (without offsetting appropriation), divided by 1,000,000 and rounded to one decimal |
| `ft_employees` | Total Personnel Costs: Total Full-Time Employees, rounded to one decimal ("No data" and "--" become `NA`) |

The sheet has a second full-time count, by department, that does not always agree with this one.

## Figures

Figures 2, 3, 4, 6, 7, 9, 10, 11, 12, and 13 and the blank grids are exactly the images in the
workbook. Figures 1 and 5 are hand-drawn in the workbook; the scripts draw clean versions of the
same diagrams. Figure 8, Figure 14, and the number line were drawn with Python for the workbook;
the scripts here draw them in R with the same geometry.
