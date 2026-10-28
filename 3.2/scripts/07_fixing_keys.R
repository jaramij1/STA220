# scripts/07_fixing_keys.R
# Workbook 3.2, Section 6, "Fixing Keys": the same 12 Mercer towns as two agencies spell them, the
# repair pipeline (str_to_lower(), str_squish(), str_replace()), anti_join() both ways to list what
# still does not match, a lookup table for the leftovers, and the trap: a code that looks like the
# key and is not. No figure; read what it prints.


# Packages and Load the Data ---------------------------------------------------------------------

library(tidyverse)

# Source 1: every New Jersey town in the 2025 sheet of the UFB Database
nj_2025 <- read_csv(
  "data/nj_2025.csv",
  col_types = cols(muni_code = col_character())   # keep the code as text: "0101", not 101
)

# One row is one NJ municipality's 2025 budget. Expect 564 rows and 18 columns.
dim(nj_2025)
names(nj_2025)
summary(nj_2025)

# Source 2: the Division of Taxation's average residential tax bill, 2024, exactly as printed
tax <- read_csv(
  "data/avg_tax_bill_2024.csv",
  col_types = cols(
    county_code = col_character(),     # "11" and "02", not 11 and 2
    district_code = col_character()
  )
)

# One row is one taxing district in 2024. Expect 564 rows and 4 columns.
dim(tax)
names(tax)
summary(tax)


# The Same 12 Towns, Two Spellings ---------------------------------------------------------------

ufb_mercer <- nj_2025 |>
  filter(county == "Mercer") |>
  select(muni_code, town)

tax_mercer <- tax |>
  filter(county_code == "11") |>
  select(county_code, district_code, district, avg_tax_bill)

ufb_mercer

tax_mercer

# A join on the raw names finds nothing: "Ewing township" is not "EWING TWP"
ufb_mercer |>
  anti_join(tax_mercer, by = c("town" = "district")) |>
  nrow()                 # 12: none match


# The Repair, One Step at a Time -----------------------------------------------------------------

# str_to_lower() fixes case. str_squish() removes extra spaces (at the ends and doubled inside).
# str_replace() rewrites one pattern; $ means "at the end of the text".
ufb_mercer <- ufb_mercer |>
  mutate(
    key = town |>
      str_to_lower() |>
      str_squish() |>
      str_replace(" township$", " twp") |>
      str_replace(" borough$", " boro")
  )

tax_mercer <- tax_mercer |>
  mutate(
    key = district |>
      str_to_lower() |>
      str_squish()
  )

ufb_mercer |>
  select(town, key)

tax_mercer |>
  select(district, key)

# anti_join() both ways: what still does not match?
anti_join(ufb_mercer, tax_mercer, by = "key")   # 1 row: "princeton boro"

anti_join(tax_mercer, ufb_mercer, by = "key")   # 1 row: "princeton"


# Inserting the Repaired Key: a Lookup Table -----------------------------------------------------

# The leftovers get a lookup table: the Division's spelling, and what it should become
fixes <- tribble(
  ~key,         ~key_fixed,
  "princeton",  "princeton boro"
)

tax_mercer <- tax_mercer |>
  left_join(fixes, by = "key") |>
  mutate(key = coalesce(key_fixed, key)) |>     # the fix, or else the key
  select(-key_fixed)

# Note on coalesce(key_fixed, key):
# It reads left-to-right. It evaluates 'key_fixed' first. If 'key_fixed' is NA, it uses 'key'.
# Because only Princeton is not NA for key fixed, only princeton will be replaced
# Pro-tip: You can Ctrl+Click on the 'coalesce' function name to view its official documentation.

# Now anti_join() returns 0 rows both ways
anti_join(ufb_mercer, tax_mercer, by = "key")   # 0 rows

anti_join(tax_mercer, ufb_mercer, by = "key")   # 0 rows


# Statewide, on County + Name --------------------------------------------------------------------

counties <- nj_2025 |>
  distinct(county_code = str_sub(muni_code, 1, 2), county)

tax_keyed_all <- tax |>
  left_join(counties, by = "county_code") |>
  mutate(
    key = district |>
      str_to_lower() |>
      str_squish()
  )

ufb_keyed_all <- nj_2025 |>
  mutate(
    key = town |>
      str_to_lower() |>
      str_squish() |>
      str_replace(" township$", " twp") |>
      str_replace(" borough$", " boro") |>
      str_replace(" city city$", " city")      # "Jersey City city" is "JERSEY CITY"
  )

ufb_keyed_all |>
  inner_join(tax_keyed_all, by = c("county", "key")) |>
  nrow()                 # 550 of 564 match

ufb_keyed_all |>
  anti_join(tax_keyed_all, by = c("county", "key")) |>
  select(county, town, key) |>
  print(n = 20)

tax_keyed_all |>
  anti_join(ufb_keyed_all, by = c("county", "key")) |>
  select(county, district, key) |>
  print(n = 20)

# The 14 leftovers, fixed by hand. Each line is a decision, and it is in the script, not in Excel.
fixes_all <- tribble(
  ~key,                        ~key_fixed,
  "fairlawn boro",             "fair lawn boro",
  "hohokus boro",              "ho-ho-kus boro",
  "caldwell boro twp",         "caldwell boro",
  "essex fells twp",           "essex fells boro",
  "glen ridge boro twp",       "glen ridge boro",
  "princeton",                 "princeton boro",
  "avon by the sea boro",      "avon-by-the-sea boro",
  "colts neck township",       "colts neck twp",
  "pt pleasant beach boro",    "point pleasant beach boro",
  "carneys point township",    "carneys point twp",
  "lower alloway creek twp",   "lower alloways creek twp",
  "peapack gladstone boro",    "peapack and gladstone boro",
  "westfield twp",             "westfield town",
  "belvidere twp",             "belvidere town"
)

tax_keyed_all <- tax_keyed_all |>
  left_join(fixes_all, by = "key") |>
  mutate(key = coalesce(key_fixed, key)) |>
  select(-key_fixed)

ufb_keyed_all |>
  anti_join(tax_keyed_all, by = c("county", "key")) |>
  nrow()                 # 0

tax_keyed_all |>
  anti_join(ufb_keyed_all, by = c("county", "key")) |>
  nrow()                 # 0

tax_keyed_all |>
  count(county, key) |>
  filter(n > 1)          # 0 rows: county + key is a key


# The Trap: a Code That Looks Like the Key -------------------------------------------------------

# The Division's county code and district code pasted together look exactly like the UFB code:
# "11" + "02" = "1102" = Ewing. In Mercer County every code agrees. Statewide they do not.
tax_keyed_all <- tax_keyed_all |>
  mutate(muni_code = paste0(county_code, district_code))

by_code <- ufb_keyed_all |>
  left_join(tax_keyed_all, by = "muni_code", suffix = c("_ufb", "_tax"))

# Three checks after the merge: expect 564 rows and 25 columns, and no NAs in avg_tax_bill
dim(by_code)
names(by_code)
summary(by_code)

sum(is.na(by_code$avg_tax_bill))     # 0: looks perfect

# But compare the repaired NAMES that the code matched up
wrong <- by_code |>
  filter(key_ufb != key_tax)

nrow(wrong)                          # 99 towns got another town's tax bill

count(wrong, county_ufb)             # Middlesex 7, Monmouth 47, Ocean 33, Salem 12

wrong |>
  filter(county_ufb == "Monmouth") |>
  select(muni_code, town, district, avg_tax_bill) |>
  head(5)

# The two agencies number towns differently in those counties. Same shape, different meaning. The
# key for THIS pair of sources is the county and the repaired name together.


# Save the Repaired Keys for the Merging Scripts -------------------------------------------------

tax_keyed_all |>
  select(county, key, district, avg_tax_bill) |>
  write_csv("data/tax_bill_2024_keyed.csv")

ufb_keyed_all |>
  select(muni_code, county, town, key) |>
  write_csv("data/nj_2025_keyed.csv")
