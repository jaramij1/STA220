# STA 220, Module 3.2: the example project

The R behind workbook 3.2 (Visualizing One, Two, Three or More Variables, getting the data, and
putting two sources into one graphic): the four sources as downloaded, every figure, the key repair, the merges, and the Practice in R tasks.
Data for Everyday Life, The College of New Jersey, fall 2026.

## For students

**Getting the files.** If you cloned the class repository for 3.1, open GitHub Desktop, click
**Fetch origin**, then **Pull origin**, and the 3.2 folder appears next to 3.1. Pulling only brings
in what changed on GitHub; your work in 3.1 stays. If GitHub Desktop says your local changes would
be overwritten, commit them first (type a summary, click **Commit to main**), then pull. Never click
**Discard changes**. If you have not cloned yet, clone the repository (clone, not fork).

Then open `3.2.Rproj` and work through `scripts/` in order:

1. `01_setup.R` is the setup check from the workbook: it installs `patchwork` and `pdftools` if
   you do not have them, reads the 2025 table, and draws one bar per kind of municipality.
2. `02_import.R` reads the four sources from `data/raw/`, exactly as they were downloaded, and
   writes the tables in `data/`. They are already there, so you only need to run it if you want
   to see how they were made. To do the same cleaning by hand, see **The four sources by hand**
   below.
3. `03` to `13` follow the workbook, one script per section. `03`, `07`, `08`, and `11` print
   evidence instead of drawing; the rest make the figures. Open any of them, run it a line at a
   time, change something, and run it again. Every table a script reads is followed by **the three
   checks**, `dim()`, `names()`, and `summary()`, with a comment saying what to expect; every
   merge is followed by them too. Do the same in your own scripts.
4. `14_practice_in_r.R` is yours to fill in: six tasks, with questions in the workbook.
5. `15_practice_solutions.R` is one way to do each task. Try first.

## What is here

```
3.2/
  3.2.Rproj                        # double-click to open the project
  README.md                        # this file
  data/
    raw/                           # the four sources exactly as downloaded. Never edit these!
      UFB.xlsm                     # Source 1: the User Friendly Budget Database (DCA), Excel
      2016AvgResTax.pdf ... AvgTax2024.pdf  # Source 2: Average Residential Tax Reports (Division of Taxation), PDF
      quickfacts_1.csv ... quickfacts_4.csv # Source 3: Census QuickFacts, six places per download, CSV
      bls_cpi_u_CUUR0000SA0.xlsx   # Source 4: CPI-U with annual averages (BLS), Excel
    avg_tax_bill_2024.csv          # made by 02_import.R from Source 2: every taxing district, 2024, names as printed
    avg_tax_bill_2024_county.csv   # made by 02_import.R from Source 2: the county averages and the state average, 2024
    mercer_tax_bill_2016_2024.csv  # made by 02_import.R from Source 2: the Mercer County rows, 2016 to 2024
    tax_bill_benchmarks_2016_2024.csv  # made by 02_import.R from Source 2: Mercer County and state averages by year
    quickfacts_near_tcnj.csv       # made by 02_import.R from Source 3: one row per place, 21 rows
    cpi_u_2016_2025.csv            # made by 02_import.R from Source 4: one row per year
    nj_2025.csv                    # made by 02_import.R: every NJ town in the 2025 sheet, one row per town
    nj_2016_2025.csv               # made by 02_import.R: every town in every budget year, one row per town-year
    ufb_mercer.csv                 # made by 02_import.R: the 12 Mercer County towns in 2025 (printed in the workbook)
    ewing.csv                      # made by 02_import.R: Ewing township, 2016 to 2025
    state_by_year.csv              # made by 02_import.R: the median NJ town's budget per resident, by year
    permits.csv                    # made by 02_import.R: MADE UP, for the Module 3.2 Practice questions
    branches.csv, branch_towns.csv # made by 02_import.R: MADE UP, for the Practice: Two Sources questions
    nj_2025_keyed.csv              # made by 07_fixing_keys.R: nj_2025 with the repaired key
    tax_bill_2024_keyed.csv        # made by 07_fixing_keys.R: Source 2 with the repaired key
    nj_merged.csv                  # made by 09_the_merge.R: Sources 1 and 2 joined, every town
    near_tcnj.csv                  # made by 10_rates_from_two_sources.R: Sources 1, 2, and 3 joined, 19 towns
  scripts/
    01_setup.R                     # the setup check
    02_import.R                    # reads the four sources from data/raw/, writes data/*.csv
    03_know_your_key.R             # Section 1: the key check (no figure)
    04_one_variable.R              # Section 2: Figures 2 to 7; count(); the plans table; bins; the blank grids
    05_two_variables.R             # Section 3: Figures 8 to 13; lm(); percent change; group_by() and summarize()
    06_three_or_more.R             # Section 4: Figures 14 to 18: color, facets, the heatmap
    07_fixing_keys.R               # Section 6: the name repair, anti_join() both ways, the lookup table, the code trap
    08_can_these_be_merged.R       # Section 6: the five questions, answered in R (no figure)
    09_the_merge.R                 # Section 6: Figure 19; the Mercer merge; the statewide merge; the paired key
    10_rates_from_two_sources.R    # Section 6: Figures 20 and 21; the tax bill as a share of income
    11_same_unit.R                 # Section 6: the library branches, summarized up to towns, then merged (no figure)
    12_reporting_a_merge.R         # Section 6: the merge report; Figure 22, the dashboard example
    13_module_practice.R           # Figures 23 and 24; the blank grids for the permits questions
    14_practice_in_r.R             # Practice in R: six tasks for students to write
    15_practice_solutions.R        # one way to do each of the six tasks
    master.R                       # source() 02 to 13 and 15, in order
  output/
    figures/                       # made by the scripts; rerun, don't edit
    ewing_vs_neighbors.png         # not in the repository: your Task 6 chart lands here
```

Each script needs only the tidyverse (plus `patchwork` for the side-by-side figures) and the files
in `data/`. `02_import.R` also needs `readxl`, which comes with the tidyverse, and `pdftools`, which
reads the text out of the tax-bill PDFs. `01_setup.R` installs both new packages if you do not have
them.

## The four sources

All four are real, public, and free. Each file in `data/raw/` is exactly what the agency's site
gave us; `02_import.R` turns each one into the tables in `data/`. If you would rather (or must) do
it by hand, the steps are in the next section. Either way, never change a file in `data/raw/`:
work on a copy.

**Source 1. The User Friendly Budget (UFB) Database**, NJ Department of Community Affairs (DCA),
Division of Local Government Services. Excel, one sheet per budget year (`2016 Summary` to
`2026 Summary`), one row per municipality, then a blank row and Minimum, Maximum, Median, and
Average rows. The towns report the figures themselves, and the database's own introduction says
they have not been independently audited or verified.
- Landing page: https://datahub.dca.nj.gov/datasets/user-friendly-budget-database
- The file: https://www.nj.gov/dca/dlgs/programs/mc_budget_docs/UFB%20Database%20-%20FINAL.xlsm
  (22 MB; DCA calls it `UFB Database - FINAL.xlsm`, renamed here `UFB.xlsm`).
- The key is `muni_code`, the state's four-character code, kept as text (`"0101"`, not 101).

**Source 2. The Average Residential Tax Report**, NJ Division of Taxation. One PDF per tax year:
county, school, and municipal taxes together, for the average home in each taxing district (one
district is one municipality). The state posts these only as PDFs.
- https://www.nj.gov/treasury/taxation/pdf/lpt/AvgResTax/AvgTax2024.pdf
- https://www.nj.gov/treasury/taxation/pdf/lpt/AvgResTax/AvgTax2023.pdf
- https://www.nj.gov/treasury/taxation/pdf/lpt/AvgResTax/2022AvgResTax.pdf, and the same pattern
  for 2016 to 2021 (`2016AvgResTax.pdf` and so on).
- The names are kept exactly as printed (`EWING TWP`, `PRINCETON`). The Division's county and
  district codes are kept as text. **They do not mean the same town as the UFB's code in four
  counties**, which `07_fixing_keys.R` shows.
- The 2025 bills are in a newer report with a different layout, *2025 Average Residential
  Statistics*, listed at https://www.nj.gov/treasury/taxation/lpt/statdata.shtml. This project
  does not read it, so 2025 is NA. (Reading it would be a good exercise.)

**Source 3. QuickFacts**, U.S. Census Bureau. For 19 towns within about half an hour of TCNJ,
plus Mercer County and New Jersey, downloaded October 23, 2026. QuickFacts shows at most six
places at a time, so there are four downloads. Most columns are American Community Survey 5-year
estimates for 2020 to 2024; `pop_2025_est` is the July 1, 2025 estimate. QuickFacts lists only
places with 5,000 or more residents, so Hopewell borough and Pennington borough are not in it.
- https://www.census.gov/quickfacts/ (search a town, add up to six places, then **Download** > CSV)
- The first download, as a link: https://www.census.gov/quickfacts/fact/table/ewingtownshipmercercountynewjersey,lawrencetownshipmercercountynewjersey,hamiltontownshipmercercountynewjersey,hopewelltownshipmercercountynewjersey,trentoncitynewjersey,princetonnewjersey/PST045225
- QuickFacts names every download `QuickFacts <date>.csv`; they are renamed here
  `quickfacts_1.csv` to `quickfacts_4.csv`.
- The town's name is the only key, written as the Census writes it ("Ewing township, Mercer
  County, New Jersey"; "Princeton, New Jersey").

**Source 4. The Consumer Price Index for All Urban Consumers (CPI-U)**, Bureau of Labor
Statistics: all items, U.S. city average, not seasonally adjusted, 1982-84 = 100.
- https://data.bls.gov/timeseries/CUUR0000SA0 (choose 2016 to 2025, tick **include annual
  averages**, click **Go**, then **Download: xlsx**). BLS names the file `SeriesReport-<date>.xlsx`;
  it is renamed here `bls_cpi_u_CUUR0000SA0.xlsx`.
- BLS published no October 2025 index, so its 2025 annual average is the mean of 11 months.
- A trusted secondary copy: FRED, at the Federal Reserve Bank of St. Louis, reposts the same series
  as CPIAUCNS.

## The four sources by hand

`02_import.R` does all of this in seconds and leaves a record of every step. These are the same
steps in Excel, for when you want to see the data with your own eyes or need to fix a file before
R can read it. Work on a **copy** of each download. Write down every change in your research log.
At the end, every table should look like 2.3's tidy table: one header row with short names and no
spaces, one row per unit, one column per variable, numbers without `$`, `,`, or `%`, and nothing
else on the sheet. Save each one with **File > Save As > CSV UTF-8 (Comma delimited)**.

**Source 1 (UFB, Excel) into `nj_2025.csv`**
1. Download the file (link above) and open a copy in Excel. If Excel asks about macros, you do
   not need them.
2. Go to the sheet `2025 Summary`. Rows 1 to 4 are a title and group headings; the column names
   are in row 5; the towns start in row 6. Some names repeat (there are many columns called
   "Total"), so read the heading above a column to know which one it is.
3. Insert a new sheet. Copy the columns you need (for example `Muni-code`, `Municipality`,
   `County`, the population, the land area, and `Total General Budget`) and paste them with
   **Paste Special > Values**.
4. Rename the headers to short names: `muni_code`, `town`, `county`, `pop`, `land_sqmi`, `budget`.
5. Scroll to the bottom and delete the blank row and the Minimum, Maximum, Median, and Average
   rows. They are not towns. You should have 564 rows of towns.
6. Missing values are written as `No data` or `--`. Use **Find & Replace** (with **Match entire
   cell contents** ticked) to replace each with nothing.
7. Format the `muni_code` column as **Text** so `0101` keeps its leading zero. (In R, read it with
   `col_types = cols(muni_code = "c")` anyway.)
8. Save as `nj_2025.csv`. For every year, repeat steps 2 to 7 for each `Summary` sheet, add a
   `year` column, and paste the years one under another (`nj_2016_2025.csv`).

**Source 2 (tax-bill PDF) into `avg_tax_bill_2024.csv`**
1. Download `AvgTax2024.pdf` (link above). It is 18 pages: a county heading, one line per town
   (district code, name, average bill), and the county's average; the state average is at the end.
2. Get the lines into Excel. On Windows with Microsoft 365: **Data > Get Data > From File > From
   PDF**, choose the file, select the page tables, and **Load**. Anywhere else: open the PDF,
   select the text of a page, copy, and paste into Excel (each line lands in column A); then
   **Data > Text to Columns > Fixed width**, with breaks between the code, the name, and the
   bill. (Splitting at every space would also split names like EAST WINDSOR TWP.)
3. Make four columns: `county_code`, `district_code`, `district`, `avg_tax_bill`. The county code
   is printed only in each county's heading (`11  MERCER COUNTY`), so type it into every town row
   of that county.
4. Delete the heading rows, the page titles, the county average rows, and the state average.
   (Copy the county and state averages to their own sheet first: they are the benchmarks.)
5. Remove the `$` and the commas from `avg_tax_bill` (Find & Replace) and format it as a number.
   Format both code columns as **Text** so `01` stays `01`.
6. Check: 564 rows. Pick five towns and compare their bills with the PDF; one typo here is one
   wrong bar on your dashboard.
7. Save as `avg_tax_bill_2024.csv`.

**Source 3 (QuickFacts, CSV) into `quickfacts_near_tcnj.csv`**
1. Download the four CSVs (six places each). Open the first copy in Excel.
2. Each row is a **fact** and each place has two columns, the value and a "Value Note". Delete the
   `Fact Note` column and every `Value Note for ...` column.
3. Delete everything below the `FIPS Code` row: those are notes, not data.
4. Delete the fact rows you do not need. Keep, for example, the 2025 population estimate, median
   household income, median home value, median gross rent, and mean travel time to work.
5. Turn it so each **place** is a row: select the block, copy, and on a new sheet use **Paste
   Special > Transpose**.
6. Rename the headers to short names: `geography`, `pop_2025_est`, `median_hh_income`,
   `median_home_value`, `median_rent`, `mean_commute_min`.
7. Remove `$`, `%`, and commas from the numbers (Find & Replace) and format them as numbers.
   A value of `X` means "not applicable": replace it with nothing.
8. Do steps 2 to 7 for the other three downloads and paste their rows under the first. Check:
   21 rows, one per place, with Mercer County and New Jersey at the bottom.
9. Save as `quickfacts_near_tcnj.csv`.

**Source 4 (CPI, Excel) into `cpi_u_2016_2025.csv`**
1. Download the Excel file (link above, with **include annual averages** ticked). Open a copy.
2. Rows 1 to 11 are notes about the series. Delete them, so `Year` is in row 1.
3. Keep the `Year` and `Annual` columns; delete the months and the halves.
4. Rename the headers `year` and `cpi_u`. Check: 10 rows, 2016 to 2025.
5. Save as `cpi_u_2016_2025.csv`.

Then read each one into R with `read_csv()` and run the key check from 2.3 before you draw anything.

`permits.csv`, `branches.csv`, and `branch_towns.csv` are invented for the practice questions. The towns in them do not exist.

## Figures

Figures 1 to 24 and the blank grids are exactly the images in the workbook. Figure 19 (the join
diagram) is drawn in R with the same tables the workbook prints.
