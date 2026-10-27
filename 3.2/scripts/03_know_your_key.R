# scripts/03_know_your_key.R
# Workbook 3.2, Section 1, "Before You Draw: Know Your Key": the key check before anything
# gets counted. No figure; read what it prints.


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

ufb_mercer <- read_csv("data/ufb_mercer.csv")

# One row is one Mercer County town in 2025. Expect 12 rows and 12 columns.
dim(ufb_mercer)
names(ufb_mercer)
summary(ufb_mercer)


# The Key Check From 2.3 -------------------------------------------------------------------------

# Say: "Count how many times each town appears, then keep the towns that appear more than
# once." You want zero rows!
ufb_mercer |>
  count(town) |>
  filter(n > 1)


# What One Repeated Row Does ---------------------------------------------------------------------

# Suppose you downloaded the Mercer towns twice and stacked the downloads with bind_rows(), and
# Ewing's row came along both times: 13 rows, 12 towns.
mercer_dup <- bind_rows(
  ufb_mercer,
  filter(ufb_mercer, town == "Ewing township")
)

dim(ufb_mercer)   # 12 rows

dim(mercer_dup)   # 13 rows

mercer_dup |>
  count(town) |>
  filter(n > 1)    # 1 row: Ewing township, n = 2. The check finds it.

# Every proportion changes, not just the Yes one
ufb_mercer |>
  count(state_plan) |>
  mutate(prop = round(n / sum(n), 2))

mercer_dup |>
  count(state_plan) |>
  mutate(prop = round(n / sum(n), 2))


# The Key in nj_2025 -----------------------------------------------------------------------------

nj_2025 |>
  count(muni_code) |>
  filter(n > 1)          # 0 rows: a key

nj_2025 |>
  count(town) |>
  filter(n > 1)          # 12 rows: not a key
#   Fairfield township 2, Franklin township 4, ...

n_distinct(nj_2025$muni_code)   # 564

n_distinct(nj_2025$town)        # 546


# What to Do About a Repeat ----------------------------------------------------------------------

# Exact copies: distinct() keeps one of each. Check dim() before and after.
mercer_dup |>
  distinct() |>
  dim()                  # back to 12 rows

# Not exact copies (two years stacked): the key is the code AND the year
nj_all <- read_csv(
  "data/nj_2016_2025.csv",
  col_types = cols(muni_code = col_character())
)

# One row is one town in one budget year. Expect 5,646 rows and 13 columns.
dim(nj_all)
names(nj_all)
summary(nj_all)

nj_all |>
  count(muni_code) |>
  filter(n > 1) |>
  nrow()                 # 565 towns repeat (once per year)

nj_all |>
  count(muni_code, year) |>
  filter(n > 1) |>
  nrow()                 # 0: code and year together are the key
