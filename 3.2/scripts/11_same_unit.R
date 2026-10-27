# scripts/11_same_unit.R
# Workbook 3.2, Section 6, "Practice: Two Sources": the made-up library branches. One row per
# branch per year cannot be joined to one row per town, so the rows get summarized UP to one per
# town and year (group_by() and summarize()), and then merged. No figure; read what it prints.


# Packages and Load the Data ---------------------------------------------------------------------

library(tidyverse)

# MADE UP: one row per library branch per year; the town names were typed by three people
branches <- read_csv("data/branches.csv")

# One row is one branch in one year. Expect 12 rows and 4 columns.
dim(branches)
names(branches)
summary(branches)

# MADE UP: one row per town, with its residents
branch_towns <- read_csv("data/branch_towns.csv")

# One row is one town. Expect 5 rows and 2 columns.
dim(branch_towns)
names(branch_towns)
summary(branch_towns)


# A Finer Unit: Repair the Key, Then Summarize Up ------------------------------------------------

# branches is one row per branch per year. branch_towns is one row per town. They cannot be
# joined as they are: a town has several branches, and the bookmobile has no town at all.
branches

branches |>
  count(town_name)       # the names were typed three ways

# Step 1: repair the key (07_fixing_keys.R), so every branch in a town spells the town the same way
branches <- branches |>
  mutate(
    key = town_name |>
      str_to_lower() |>
      str_squish() |>
      str_replace(" township$", " twp") |>
      str_replace(" borough$", " boro")
  )

branches |>
  count(key)

# Step 2: collapse to one row per town and year. Say: "group the rows by town and year, and then
# collapse each group to one row with the number of branches and the total visits."
visits <- branches |>
  filter(!is.na(key)) |>          # the bookmobile: say in the caption that it is left out
  group_by(key, year) |>
  summarize(
    branches = n(),
    visits = sum(visits),
    .groups = "drop"
  )

# One row is one town in one year. Expect 8 rows (4 towns x 2 years) and 4 columns.
dim(visits)
names(visits)
summary(visits)

visits |>
  count(key, year) |>
  filter(n > 1)          # 0 rows: now key + year is a key


# Step 3: The Merge, Predicted First -------------------------------------------------------------

branch_towns <- branch_towns |>
  mutate(
    key = town |>
      str_to_lower() |>
      str_replace(" township$", " twp") |>
      str_replace(" borough$", " boro")
  )

# Before the merge, what I expect:
# 1) Rows: visits is the left table, so 8 rows in and 8 rows out.
# 2) Columns: 4 + 3 - 1 = 6 (the key is counted once).
# 3) Drops: none on the left; Stony Brook on the right (it has no branch).
anti_join(visits, branch_towns, by = "key")   # expect 0 rows

anti_join(branch_towns, visits, by = "key")   # expect 1 row: Stony Brook borough

visits_per_resident <- visits |>
  left_join(branch_towns, by = "key") |>
  mutate(per_resident = round(visits / residents, 2))

# Three checks after the merge: expect 8 rows and 7 columns (with per_resident)
dim(visits_per_resident)
names(visits_per_resident)
summary(visits_per_resident)

visits_per_resident
