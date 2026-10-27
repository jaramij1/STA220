# scripts/08_can_these_be_merged.R
# Workbook 3.2, Section 6, "Can These Be Merged? Five Questions": the evidence for each answer, for
# two pairs of sources. Pair 1 is the UFB Database (Source 1) and the Division of Taxation's
# average tax bill (Source 2). Pair 2 is the UFB Database and Census QuickFacts (Source 3).
# No figure; read what it prints.


# Packages and Load the Data ---------------------------------------------------------------------

library(tidyverse)

nj_2025 <- read_csv(
  "data/nj_2025.csv",
  col_types = cols(muni_code = col_character())   # keep the code as text: "0101", not 101
)

# One row is one NJ municipality's 2025 budget. Expect 564 rows and 18 columns.
dim(nj_2025)
names(nj_2025)
summary(nj_2025)

tax <- read_csv(
  "data/avg_tax_bill_2024.csv",
  col_types = cols(
    county_code = col_character(),
    district_code = col_character()
  )
)

# One row is one taxing district in 2024. Expect 564 rows and 4 columns.
dim(tax)
names(tax)
summary(tax)

quickfacts <- read_csv(
  "data/quickfacts_near_tcnj.csv",
  col_types = cols(fips = col_character())
)

# One row is one place. Expect 21 rows and 21 columns.
dim(quickfacts)
names(quickfacts)
summary(quickfacts)


# Pair 1: Budgets (UFB, 2025) and the Average Tax Bill (Taxation, 2024) --------------------------

# 1. Unit of analysis: is one row the same thing in both?
dim(nj_2025)        # 564 rows: one row is one municipality in budget year 2025

dim(tax)            # 564 rows: one row is one taxing district in tax year 2024. A district IS a municipality.

# 2. Time: do the two sources cover the same years?
# Budget year 2025 (the budget the town adopted for 2025) and tax year 2024 (the bills that went
# out in 2024). Not the same year. The merge pairs them anyway; the caption has to say so.

# 3. Key: is there a column, or a pair of columns, that identifies the unit, and does it pass the
#    key check in BOTH tables?
nj_2025 |>
  count(muni_code) |>
  filter(n > 1) |>
  nrow()                 # 0: the code is a key

tax |>
  count(county_code, district_code) |>
  filter(n > 1) |>
  nrow()                 # 0: county + district is a key

nj_2025 |>
  count(town) |>
  filter(n > 1) |>
  nrow()                 # 12: the name alone is not

tax |>
  count(district) |>
  filter(n > 1)          # 12 rows, nor is the Division's name: WASHINGTON TWP 5, FRANKLIN TWP 4, ...

# 4. Format: is the key written the same way in both?
head(nj_2025$town, 3)        # "Absecon city"  Title case, the full word

head(tax$district, 3)        # "ABSECON CITY"  CAPS, and later TWP and BORO

# The codes look alike ("0101" vs "01" + "01") but 07_fixing_keys.R shows they do not mean the
# same town in four counties. So the key is county + repaired name, not the code.

# 5. Coverage: how many rows will match, which will not, and why?
# After the repairs in 07_fixing_keys.R: 550 match on county + name, 14 need a lookup table, and
# then all 564 match. One matched row still has an impossible value:
tax |>
  filter(avg_tax_bill == 0)    # AUDUBON PARK BORO, $0: matched is not the same as complete

# Verdict: merge after a fix you can name (repair the names; keep the county in the key), and
# turn the $0 into NA before you compute anything.


# Pair 2: Budgets (UFB, 2025) and QuickFacts (Census, 2020-2024 ACS) -----------------------------

# 1. Unit of analysis: 21 rows, 19 towns plus Mercer County and New Jersey, which are not towns
quickfacts |>
  select(geography, pop_2025_est)

# 2. Time: the ACS numbers are five-year averages, 2020 to 2024; the population estimate is July 2025

# 3. Key: only the name. Is it a key in both?
quickfacts |>
  count(geography) |>
  filter(n > 1) |>
  nrow()                 # 0

# 4. Format: "Ewing township, Mercer County, New Jersey" vs "Ewing township"
head(quickfacts$geography, 3)

# 5. Coverage: 19 of the 564 towns. Two Mercer towns are missing on purpose: QuickFacts only
#    publishes places with 5,000 or more residents.
nj_2025 |>
  filter(county == "Mercer", pop < 5000) |>
  select(town, pop)      # Hopewell borough, Pennington borough

# Verdict: merge after a fix (drop the two benchmark rows; cut the name at the first comma), and
# expect 19 matches out of 564. Fine for a dashboard about the towns near TCNJ; useless as a
# statewide benchmark. The benchmark rows are the benchmark: keep them in a table of their own.
