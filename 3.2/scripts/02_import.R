# scripts/02_import.R

# NOTE: You do NOT need to learn every command in this script.
# It rebuilds every table workbook 3.2 prints, starting from the files exactly as they were
# downloaded. Borrow from it freely. Two things ARE worth your attention: the key check before
# anything gets counted (count() then filter(n > 1)), and that every change to a source is made
# here, in a script anyone can rerun, never by hand in Excel.
#
# Workbook 3.2 uses FOUR real, public sources. Each one sits in data/raw/ exactly as it came from
# the agency that publishes it. Never edit those files! To do the same cleaning by hand (in Excel,
# not R), follow "The four sources by hand" in README.md, or the workbook's appendix.
#
#   Source 1: data/raw/UFB.xlsm, the User Friendly Budget (UFB) Database, NJ Department of
#             Community Affairs (DCA). One sheet per budget year, one row per municipality.
#             Landing page: https://datahub.dca.nj.gov/datasets/user-friendly-budget-database
#             The file:     https://www.nj.gov/dca/dlgs/programs/mc_budget_docs/UFB%20Database%20-%20FINAL.xlsm
#             (DCA names it "UFB Database - FINAL.xlsm"; it was renamed UFB.xlsm.)
#   Source 2: data/raw/2016AvgResTax.pdf ... AvgTax2024.pdf, the NJ Division of Taxation's
#             "Average Residential Tax Report", one PDF per tax year. The state posts only PDFs:
#             https://www.nj.gov/treasury/taxation/pdf/lpt/AvgResTax/AvgTax2024.pdf
#             https://www.nj.gov/treasury/taxation/pdf/lpt/AvgResTax/AvgTax2023.pdf
#             https://www.nj.gov/treasury/taxation/pdf/lpt/AvgResTax/2022AvgResTax.pdf
#             (and 2016AvgResTax.pdf to 2021AvgResTax.pdf at the same address)
#             The 2025 bills are in a newer report with a different layout, "2025 Average
#             Residential Statistics" (https://www.nj.gov/treasury/taxation/lpt/statdata.shtml).
#             This script does not read it, so 2025 is NA.
#   Source 3: data/raw/quickfacts_1.csv ... quickfacts_4.csv, Census Bureau QuickFacts, six places
#             per download (19 towns near TCNJ, Mercer County, and New Jersey). For example:
#             https://www.census.gov/quickfacts/fact/table/ewingtownshipmercercountynewjersey/PST045225
#             then "Download" > CSV. QuickFacts names every file "QuickFacts <date>.csv"; they were
#             renamed quickfacts_1.csv to quickfacts_4.csv. Downloaded October 23, 2026.
#   Source 4: data/raw/bls_cpi_u_CUUR0000SA0.xlsx, the Consumer Price Index for All Urban
#             Consumers (CPI-U), Bureau of Labor Statistics, 2016 to 2025, "include annual averages":
#             https://data.bls.gov/timeseries/CUUR0000SA0 (then "Download: xlsx")
#
# This script writes the tables the other scripts read:
#   data/nj_2025.csv                    Source 1: every town in the 2025 sheet, 564 rows
#   data/nj_2016_2025.csv               Source 1: every town in every budget year, one row per town-year
#   data/ufb_mercer.csv                 Source 1: the 12 Mercer County towns in 2025 (printed in the workbook)
#   data/ewing.csv                      Source 1: Ewing township, 2016 to 2025, one row per year
#   data/state_by_year.csv              Source 1: the median NJ town's budget per resident, by year
#   data/avg_tax_bill_2024.csv          Source 2: every taxing district in 2024, names exactly as printed
#   data/avg_tax_bill_2024_county.csv   Source 2: the 21 county averages and the state average, 2024
#   data/mercer_tax_bill_2016_2024.csv  Source 2: the Mercer County rows of the 2016 to 2024 reports
#   data/tax_bill_benchmarks_2016_2024.csv  Source 2: the Mercer County and state averages by year
#   data/quickfacts_near_tcnj.csv       Source 3: one row per place, 21 rows
#   data/cpi_u_2016_2025.csv            Source 4: the annual averages, one row per year
#   data/permits.csv                    MADE UP: 16 building permits for the Module 3.2 Practice section
#   data/branches.csv                   MADE UP: library branch visits for the Practice: Two Sources questions
#   data/branch_towns.csv               MADE UP: the residents of the towns those branches serve


# Packages ---------------------------------------------------------------------------------------

library(tidyverse)
library(readxl)     # comes with the tidyverse
library(pdftools)   # reads the text out of a PDF; 01_setup.R installs it


# Source 1: the UFB Database (Excel) -------------------------------------------------------------

ufb <- "data/raw/UFB.xlsm"

stopifnot(file.exists(ufb))

# How a Summary sheet is laid out:
# Row 1 is blank, row 2 is a title, row 3 holds group headers, row 4 holds subgroup headers,
# row 5 holds the column names, and the data start in row 6. The column names repeat ("Total"
# appears many times), so a column is identified by its subgroup header and its name together.
# After the municipalities come a blank row and four summary rows: Minimum, Maximum, Median,
# and Average. Missing values are written as "No data" or "--".
read_ufb <- function(year) {

  sheet <- paste(year, "Summary")

  header <- read_excel(
    ufb,
    sheet = sheet,
    skip = 2,
    n_max = 3,
    col_names = FALSE,
    .name_repair = "minimal"
  )

  subgroup  <- vctrs::vec_fill_missing(as.character(header[2, ]), direction = "down")
  name      <- as.character(header[3, ])

  stopifnot(name[1] == "Muni-code")

  full_name <- if_else(is.na(subgroup), name, paste(subgroup, name, sep = " | "))

  out <- read_excel(
    ufb,
    sheet = sheet,
    skip = 5,
    col_names = full_name,
    na = c("", "No data", "--"),
    .name_repair = "minimal"
  ) |>
    select(
      muni_code     = 1,                 # the text code, "0101". Column 2 is the same code
      town          = 3,                 #   stored as a number, 101. Not today!
      county        = 4,
      pop           = matches("^Population and Density \\| (\\d{4} )?Population( \\(|$| Estimate)"),
      land_sqmi     = matches("^Population and Density \\| .*Land Area"),
      budget        = matches("General Budget Appropriations \\| Total General Budget$"),
      levy          = matches("Total Anticipated Revenues.*\\| Local Tax for Municipal Purposes"),
      state_aid     = matches("Total Anticipated Revenues.*\\| State Aid"),
      surplus       = matches("Total Anticipated Revenues.*\\| Surplus$"),   # "surplus used as revenue"
      ft_employees  = matches("^Total Personnel Costs \\| Total Full-Time Employees"),
      police_ft     = matches("^Police Officer Personnel Costs \\| .*# of Full-Time"),
      police_cost   = matches("^Police Officer Personnel Costs \\| .*Total Personnel Cost"),
      state_plan    = matches("^Health Plan Information \\| Use State Health Benefits Plan"),
      cost_share    = matches("^Active Employees - Total Health Care Cost \\| Avg. Employee Cost Sharing"),
      pct_collected = matches("^Tax Collections and Delinquent Taxes \\| % of Taxes Collected"),
      net_debt_pc   = matches("^Net Debt \\| Per Capita Net Debt"),
      sp_rating     = matches("^Credit Ratings \\| S&P Rating$")
    ) |>
    mutate(year = year, .before = 1)

  stopifnot(ncol(out) == 18)    # each pattern must match exactly one column

  out
}

# Every town, 2016 to 2025.
# Towns have a four-character code; the blank row and the summary rows do not.
nj_all <- map(2016:2025, read_ufb) |>
  list_rbind() |>
  filter(str_length(muni_code) == 4) |>
  mutate(
    across(c(pop:net_debt_pc, -state_plan), as.numeric),
    type = str_to_lower(word(town, -1))      # the last word of the name: borough, township, ...
  )

# One row is one town in one budget year. Expect 5,646 rows and 19 columns.
dim(nj_all)
names(nj_all)
summary(nj_all)

count(nj_all, year)   # 565 towns through 2021, then 564: Pine Valley borough merged into Pine Hill


# The Key Check From 2.3, Before Anything Gets Counted ----------------------------------------------

towns_2025 <- nj_all |>
  filter(year == 2025)

stopifnot(nrow(towns_2025) == 564)

towns_2025 |>
  count(muni_code) |>
  filter(n > 1)          # 0 rows: the four-character code is the key

towns_2025 |>
  count(town) |>
  filter(n > 1)          # 12 rows: a NAME is not a key (five Washington townships)

nj_all |>
  count(muni_code) |>
  filter(n > 1) |>
  nrow()                 # 565 rows: in the stacked table the code repeats

nj_all |>
  count(muni_code, year) |>
  filter(n > 1)          # 0 rows: the code AND the year together are the key


# Count Before You Draw ------------------------------------------------------------------------------

count(towns_2025, type, sort = TRUE)   # borough 253, township 241, city 52, town 15, village 3

towns_2025 |>
  count(sp_rating, sort = TRUE) |>
  print(n = 14)          # the same rating typed many ways


# The Source 1 Tables ----------------------------------------------------------------------------------

nj_2025 <- towns_2025 |>
  transmute(
    muni_code, town, county, type,
    pop,
    density           = round(pop / land_sqmi),            # residents per square mile (before the area is rounded)
    land_sqmi         = round(land_sqmi, 1),
    budget_m          = round(budget / 1e6, 1),            # dollars to millions, one decimal
    levy_m            = round(levy / 1e6, 1),              # the municipal-purpose property tax levy
    state_aid_m       = round(state_aid / 1e6, 1),
    ft_employees      = round(ft_employees, 1),
    police_ft         = round(police_ft, 1),
    police_cost_m     = round(police_cost / 1e6, 1),
    state_plan,                                            # "Yes", "No", or NA
    cost_share        = round(100 * cost_share, 1),        # 0.252 becomes 25.2 percent
    pct_collected     = round(100 * pct_collected, 1),     # 0.989 becomes 98.9 percent
    debt_per_resident = round(net_debt_pc),                # whole dollars
    sp_rating                                              # left exactly as typed
  ) |>
  arrange(county, town)

# One row is one NJ municipality's 2025 budget. Expect 564 rows and 18 columns.
dim(nj_2025)
names(nj_2025)
summary(nj_2025)

count(nj_2025, state_plan)              # Yes 295, No 202, NA 67

sum(is.na(nj_2025$budget_m))            # towns that had not filed a 2025 budget

nj_2016_2025 <- nj_all |>
  select(
    muni_code, town, county, type, year, pop, land_sqmi, budget, levy,
    ft_employees, police_ft, police_cost, net_debt_pc
  ) |>
  arrange(year, muni_code)

ufb_mercer <- nj_2025 |>
  filter(county == "Mercer") |>
  select(
    town, type, pop, land_sqmi, density, budget_m, levy_m, ft_employees, police_ft,
    state_plan, cost_share, debt_per_resident
  ) |>
  arrange(town)

# One row is one Mercer County town in 2025. Expect 12 rows and 12 columns.
dim(ufb_mercer)

# Ewing, one row per budget year. per_resident uses the exact budget, so it can differ by a
# dollar from what you get from the rounded budget_m. That is rounding, not a mistake.
ewing <- nj_2016_2025 |>
  filter(town == "Ewing township", county == "Mercer") |>
  transmute(
    year,
    budget_m     = round(budget / 1e6, 1),
    levy_m       = round(levy / 1e6, 1),
    pop,
    per_resident = round(budget / pop),
    police_ft
  )

# One row is one budget year. Expect 10 rows and 6 columns.
dim(ewing)

# The state benchmark: the median town's budget per resident, in each year
state_by_year <- nj_2016_2025 |>
  filter(!is.na(budget), !is.na(pop), budget > 0, pop > 0) |>
  mutate(per_resident = budget / pop) |>
  group_by(year) |>
  summarize(
    towns = n(),
    median_per_resident = round(median(per_resident))
  )

# One row is one budget year. Expect 10 rows and 3 columns.
dim(state_by_year)


# Source 2: the Average Residential Tax Bill (PDF) -----------------------------------------------

# A PDF is a picture of a table, not a table. pdf_text() gives back each page as one long piece
# of text; str_split() cuts it into lines. Each kind of line is then picked out by its pattern:
#   a county heading, no dollar amount:   "11                   MERCER COUNTY"
#   a town:   (county code) district code, name, amount:   "     02   EWING TWP     $8,096"
#   the county average, no codes:         "                     MERCER COUNTY        $9,543"
#   the state average:                    "                     STATE AVERAGE:       $9,898"
# The 2016 to 2021 reports print the county code on every row; the 2022 to 2024 reports print it
# only in the county heading, so fill() copies it down. The names are kept exactly as printed.
read_tax_pdf <- function(file, year) {

  lines <- pdf_text(file) |>
    str_split("\n") |>
    unlist()

  town  <- str_match(lines, "^\\s*(?:(\\d{2})\\s+)?(\\d{2})\\s{2,}(\\S.*?)\\s{2,}\\$?([0-9,]+)\\s*$")
  total <- str_match(lines, "^\\s*(?:\\d{2}\\s+00\\s+)?([A-Z .'-]+ COUNTY)\\s{2,}\\$?([0-9,]+)\\s*$")

  tibble(
    tax_year      = year,
    county_code   = coalesce(
      town[, 2],
      str_match(lines, "^\\s*(\\d{2})\\s+[A-Z .'-]+COUNTY\\s*$")[, 2]
    ),
    district_code = town[, 3],
    district      = str_squish(town[, 4]),
    avg_tax_bill  = parse_number(town[, 5]),
    county        = total[, 2],
    county_avg    = parse_number(total[, 3]),
    state_avg     = parse_number(str_match(lines, "STATE AVERAGE:?\\s+\\$?([0-9,]+)")[, 2])
  ) |>
    fill(county_code)                       # a heading's code applies to the rows below it
}

tax_files <- c(
  paste0("data/raw/", 2016:2022, "AvgResTax.pdf"),
  "data/raw/AvgTax2023.pdf",
  "data/raw/AvgTax2024.pdf"
)

tax_lines <- map2(tax_files, 2016:2024, read_tax_pdf) |>
  list_rbind()

# The towns: every line with a district code (the 2016 county averages carry the code "00")
tax_towns <- tax_lines |>
  filter(!is.na(district_code), district_code != "00", !str_detect(district, " COUNTY$")) |>
  select(tax_year, county_code, district_code, district, avg_tax_bill)

# One row is one taxing district in one tax year. Expect 5,081 rows and 5 columns.
dim(tax_towns)
names(tax_towns)
summary(tax_towns)

count(tax_towns, tax_year)   # 564 or 565 a year (Pine Valley merged into Pine Hill in 2022)

tax_towns |>
  filter(tax_year == 2024) |>
  count(county_code, district_code) |>
  filter(n > 1)              # 0 rows: county code + district code is a key

county_avgs <- tax_lines |>
  filter(!is.na(county_avg)) |>
  distinct(tax_year, county_code, county, avg_tax_bill = county_avg)

state_avgs <- tax_lines |>
  filter(!is.na(state_avg)) |>
  distinct(tax_year, state_avg)

stopifnot(nrow(state_avgs) == 9, all(count(county_avgs, tax_year)$n == 21))

tax_2024 <- tax_towns |>
  filter(tax_year == 2024) |>
  select(-tax_year)

stopifnot(nrow(tax_2024) == 564)

tax_2024_county <- county_avgs |>
  filter(tax_year == 2024) |>
  select(county_code, county, avg_tax_bill) |>
  add_row(
    county = "STATE AVERAGE",
    avg_tax_bill = state_avgs$state_avg[state_avgs$tax_year == 2024]
  )

mercer_tax_years <- tax_towns |>
  filter(county_code == "11")

stopifnot(nrow(mercer_tax_years) == 12 * 9)

tax_benchmarks <- county_avgs |>
  filter(county_code == "11") |>
  select(tax_year, mercer_county_avg = avg_tax_bill) |>
  left_join(state_avgs, by = "tax_year")

tax_benchmarks


# Source 3: Census QuickFacts (CSV) --------------------------------------------------------------

# Each download has one row per FACT and two columns per PLACE (the value and a "Value Note"),
# numbers stored as text ("$91,267", "15.2%", "X" for not applicable), and notes at the bottom.
# So: read everything as text, drop the note columns and the notes below "FIPS Code", turn the
# places into rows (pivot_longer), then the facts into columns (pivot_wider), then make numbers.
read_qf <- function(file) {

  read_csv(
    file,
    col_types = cols(.default = col_character())
  ) |>
    select(-`Fact Note`, -starts_with("Value Note")) |>
    filter(row_number() <= which(Fact == "FIPS Code")) |>
    pivot_longer(-Fact, names_to = "geography", values_to = "value")
}

qf_long <- list.files("data/raw", pattern = "^quickfacts_\\d\\.csv$", full.names = TRUE) |>
  map(read_qf) |>
  list_rbind()

# The facts kept, and the short column name each one gets (new name = "fact as QuickFacts prints it")
facts <- c(
  pop_2025_est          = "Population estimates, July 1, 2025, (V2025)",
  pop_2020_census       = "Population, Census, April 1, 2020",
  pct_under_18          = "Persons under 18 years, percent",
  pct_65_plus           = "Persons 65 years and over, percent",
  owner_occupied_pct    = "Owner-occupied housing unit rate, 2020-2024",
  median_home_value     = "Median value of owner-occupied housing units, 2020-2024",
  median_rent           = "Median gross rent, 2020-2024",
  households            = "Households, 2020-2024",
  persons_per_household = "Persons per household, 2020-2024",
  bachelors_pct         = "Bachelor's degree or higher, percent of persons age 25 years+, 2020-2024",
  labor_force_pct       = "In civilian labor force, total, percent of population age 16 years+, 2020-2024",
  mean_commute_min      = "Mean travel time to work (minutes), workers age 16 years+, 2020-2024",
  median_hh_income      = "Median households income (in 2024 dollars), 2020-2024",
  per_capita_income     = "Per capita income in past 12 months (in 2024 dollars), 2020-2024",
  poverty_pct           = "Persons in poverty, percent",
  pop_per_sqmi_2020     = "Population per square mile, 2020",
  land_sqmi_2020        = "Land area in square miles, 2020",
  foreign_born_pct      = "Foreign-born persons, percent, 2020-2024",
  same_house_pct        = "Living in the same house 1 year ago, percent of persons age 1 year+ , 2020-2024"
)

stopifnot(all(facts %in% qf_long$Fact))      # stops if QuickFacts renames a fact

quickfacts <- qf_long |>
  filter(Fact %in% c(facts, "FIPS Code")) |>
  mutate(name = if_else(Fact == "FIPS Code", "fips", names(facts)[match(Fact, facts)])) |>
  select(geography, name, value) |>
  pivot_wider(names_from = name, values_from = value) |>
  mutate(
    fips = str_remove_all(fips, "\""),                       # "3402122185" arrives in quotes
    across(
      -c(geography, fips),                                   # "$91,267" becomes 91267: drop the
      \(x) parse_double(str_remove_all(x, "[$,%]"))          #   $ , and % signs, then read the number
    )
  ) |>
  select(geography, fips, all_of(names(facts)))

# One row is one place (19 towns, Mercer County, and New Jersey). Expect 21 rows and 21 columns.
dim(quickfacts)
names(quickfacts)
summary(quickfacts)

quickfacts |>
  count(geography) |>
  filter(n > 1)          # 0 rows: one row per place


# Source 4: the Consumer Price Index (Excel) -----------------------------------------------------

# Eleven lines of notes sit above the table, so skip = 11. Keep the year and the annual average.
# (BLS published no October 2025 index, so its 2025 annual average is the mean of 11 months.)
cpi <- read_excel(
  "data/raw/bls_cpi_u_CUUR0000SA0.xlsx",
  skip = 11
) |>
  transmute(
    year = as.integer(Year),
    cpi_u = Annual
  )

# One row is one year. Expect 10 rows and 2 columns.
dim(cpi)
names(cpi)
summary(cpi)


# The Made-Up Tables for the Practice Questions ----------------------------------------------------

# permits: building permits a classmate pulled for their dashboard. cost_k is the estimated cost
# of the work in thousands of dollars. One row is in here twice ON PURPOSE: the practice asks you
# to find it with permits |> count(permit_id) |> filter(n > 1).
permits <- tribble(
  ~permit_id, ~type,      ~cost_k,
  "P-101",    "roof",          18,
  "P-102",    "deck",          22,
  "P-103",    "solar",         31,
  "P-104",    "roof",          14,
  "P-105",    "pool",          65,
  "P-106",    "solar",         28,
  "P-107",    "roof",          21,
  "P-108",    "addition",     140,
  "P-109",    "deck",           9,
  "P-110",    "solar",         35,
  "P-111",    "roof",          16,
  "P-112",    "pool",          48,
  "P-113",    "deck",          27,
  "P-114",    "roof",          12,
  "P-115",    "solar",         26,
  "P-110",    "solar",         35
)

# branches and branch_towns: a made-up county library system, for the merging questions. One row
# of branches is one branch in one year; the town names were typed by three different people.
branches <- tribble(
  ~branch,            ~town_name,         ~year, ~visits,
  "Main",             "Riverton Twp",      2024,  61200,
  "Main",             "Riverton Twp",      2025,  64900,
  "Mill Street",      "Riverton twp ",     2024,  18400,
  "Mill Street",      "Riverton Twp",      2025,  17950,
  "Oak Hill",         "OAK HILL BORO",     2024,  22100,
  "Oak Hill",         "Oak Hill Borough",  2025,  23800,
  "Cedar Lane",       "Cedar Lane Boro",   2024,   9600,
  "Cedar Lane",       "Cedar Lane Boro",   2025,   9900,
  "Greenfield",       "Greenfield Township", 2024, 30500,
  "Greenfield",       "Greenfield Township", 2025, 33100,
  "Bookmobile",       NA,                  2024,   4100,
  "Bookmobile",       NA,                  2025,   4400
)

branch_towns <- tribble(
  ~town,                ~residents,
  "Riverton township",       41200,
  "Oak Hill borough",        12800,
  "Cedar Lane borough",       3900,
  "Greenfield township",     19700,
  "Stony Brook borough",      6100
)


# Save ---------------------------------------------------------------------------------------------

write_csv(nj_2025,          "data/nj_2025.csv")
write_csv(nj_2016_2025,     "data/nj_2016_2025.csv")
write_csv(ufb_mercer,       "data/ufb_mercer.csv")
write_csv(ewing,            "data/ewing.csv")
write_csv(state_by_year,    "data/state_by_year.csv")
write_csv(tax_2024,         "data/avg_tax_bill_2024.csv")
write_csv(tax_2024_county,  "data/avg_tax_bill_2024_county.csv", na = "")
write_csv(mercer_tax_years, "data/mercer_tax_bill_2016_2024.csv")
write_csv(tax_benchmarks,   "data/tax_bill_benchmarks_2016_2024.csv")
write_csv(quickfacts,       "data/quickfacts_near_tcnj.csv")
write_csv(cpi,              "data/cpi_u_2016_2025.csv")
write_csv(permits,          "data/permits.csv")
write_csv(branches,         "data/branches.csv")
write_csv(branch_towns,     "data/branch_towns.csv")

ufb_mercer

ewing

state_by_year
