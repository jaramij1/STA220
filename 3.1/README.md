# STA 220, Module 3.1



## How to use

Clone this repository (clone, not fork), open `3.1.Rproj`, and work through `scripts/` in order:

1. `01_setup.R` is the setup check from the workbook. Run it once; it installs the packages
   Module 3 needs.
2. `02_import.R` reads the database and writes the small tables in `data/`. They are already
   in the project, so you only need to run it if you want to see how they were made.
3. `03` to `10` make the figures in the workbook, one script per section. Open any of them, run
   it a line at a time, change something, and run it again. You can use this code
   to produce similar figures in your final project if you'd like. 
5. `11_practice_in_r.R` is yours to fill in: five tasks comparing New Jersey's college towns,
   one page of questions each in the workbook. You only need the code taught in the workbook.
7. `12_practice_solutions.R` is one way to make each of the five figures. Try first before
   jumping right to the solutions!

## The data

`data/UFB.xlsm` is the User Friendly Budget Database published by the New Jersey Department of
Community Affairs, Division of Local Government Services. One sheet per budget year, 2016 to 2026;
one row per municipality that filed a User Friendly Budget, plus Minimum, Maximum, Median, and
Average rows at the bottom. The figures are self-reported by the municipalities and, as the
database's own introduction says, have not been independently audited or verified. 

Downloaded in October 2026.

In 02_import.R, the data is imported in a more user-friendly format. You can use this code in your project
or you can manually change the dataframe by hand - report either in your README!

## Figures

This project includes the code needed to produce most of the images in the workbook.
Much of the figure code was produced by Claude - an AI tool - and edited by me to 
better match the workbook's needs. You are not responsible
for knowing or understanding all of this code, but I provide it anyway for transparency. 

The code you are responsible for is in the workbook, which you should use to complete the practice
script, which asks you to create five figures. The code written in the practice script 
follows conventions of the workbook, and you are responsible for understanding it and being
able to produce it. 
