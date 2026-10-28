# scripts/15_practice_solutions.R
# One way to do each of the six Practice in R tasks. Look only after you have tried!
# Every task starts with the three checks: dim(), names(), and summary().


# Packages and Load the Data ---------------------------------------------------------------------

library(tidyverse)

# Source 1: every New Jersey town in the 2025 sheet of the UFB Database
nj_2025 <- read_csv(
  "data/nj_2025.csv",
  col_types = cols(muni_code = col_character()) # ensure muni_code stays a character
)

# Source 1 again: every town in every budget year, 2016 to 2025, with the budget in dollars
nj_all <- read_csv(
  "data/nj_2016_2025.csv",
  col_types = cols(muni_code = col_character())
)

# Source 2: the Division of Taxation's average residential tax bill, 2024, as printed
tax <- read_csv(
  "data/avg_tax_bill_2024.csv",
  col_types = cols(
    county_code = col_character(),     # "11", not 11
    district_code = col_character()    # "02", not 2
  )
)

# Source 3: Census QuickFacts for 19 towns near TCNJ, plus Mercer County and New Jersey
quickfacts <- read_csv(
  "data/quickfacts_near_tcnj.csv",
  col_types = cols(fips = col_character())
)


# Task 1. Know Your Key, Then Count --------------------------------------------------------------

# One row is one NJ municipality's 2025 budget. Expect 564 rows and 18 columns.
dim(nj_2025)
names(nj_2025)
summary(nj_2025)

# Is muni_code a key? This should return zero rows.
nj_2025 |>
  count(muni_code) |>
  filter(n > 1)          # 0 rows: the code is the key

# Is town a key? It is not.
nj_2025 |>
  count(town) |>
  filter(n > 1) |>
  arrange(desc(n))       # 12 rows: Washington township repeats the most (5)

n_distinct(nj_2025$muni_code)   # 564

n_distinct(nj_2025$town)        # 546

# The frequency table, with a proportion column
counties <- nj_2025 |>
  count(county) |>
  mutate(prop = n / sum(n)) |>
  arrange(desc(n))

# Interpret: 2.1 percent of towns in New Jersey are in Mercer County. 

# One row is one county. Expect 21 rows and 3 columns.
dim(counties)

counties                 # Bergen 70 towns, 0.124 of the state; Mercer 12, tied for the fewest

# The bar chart, sorted, with the county with the most towns on top
ggplot(nj_2025, aes(y = fct_rev(fct_infreq(county)))) +
  geom_bar()


# Task 2. One Number, Two Bin Widths -------------------------------------------------------------

# The same table as Task 1: 564 rows and 18 columns. density is residents per square mile.
dim(nj_2025)
names(nj_2025)
summary(nj_2025)        # density runs from 0 (Walpack) to 61,886 (Guttenberg)

ggplot(nj_2025, aes(x = density)) +
  geom_histogram()      # the message: `stat_bin()` using `bins = 30`. A message, not an error.

under_15k <- nj_2025 |>
  filter(density <= 15000)

# Expect 545 rows and 18 columns: the filter removed 19 towns
dim(under_15k)
names(under_15k)
summary(under_15k)

ggplot(under_15k, aes(x = density)) +
  geom_histogram(binwidth = 500, boundary = 0)

ggplot(under_15k, aes(x = density)) +
  geom_histogram(binwidth = 2500, boundary = 0)


# Task 3. Two Variables: Ewing Over Time, Against the State --------------------------------------

# One row is one town in one budget year. Expect 5,646 rows and 13 columns.
dim(nj_all)
names(nj_all)
summary(nj_all)

nj_all <- nj_all |>
  mutate(per_resident = budget / pop)

# Tiny towns budget the most per resident: that is why the median is the benchmark, not the mean
nj_all |>
  slice_max(per_resident, n = 3) |>
  select(town, year, budget, pop, per_resident)

ewing <- nj_all |>
  filter(town == "Ewing township", county == "Mercer")

# One row is one of Ewing's budget years. Expect 10 rows and 14 columns.
dim(ewing)
names(ewing)
summary(ewing)

ewing |>
  filter(year %in% c(2016, 2025)) |>
  select(year, budget, per_resident)

(1621 - 1216) / 1216 * 100     # Ewing: 33.3 percent

state_by_year <- nj_all |>
  filter(!is.na(per_resident), budget > 0, pop > 0) |>
  group_by(year) |>
  summarize(
    towns = n(),
    median_per_resident = median(per_resident)
  )

# One row is one budget year. Expect 10 rows and 3 columns.
dim(state_by_year)
names(state_by_year)
summary(state_by_year)

(1679 - 1319) / 1319 * 100     # the median town: 27.3 percent. Ewing grew faster.

ggplot(ewing, aes(x = year, y = per_resident)) +
  geom_line() +
  geom_point() +
  geom_line(
    data = state_by_year,
    aes(x = year, y = median_per_resident),
    linetype = "dashed"
  )

# The scatterplot of two numbers, with the line R fits
ufb_mercer <- nj_2025 |>
  filter(county == "Mercer")

# One row is one Mercer County town in 2025. Expect 12 rows and 18 columns.
dim(ufb_mercer)
names(ufb_mercer)
summary(ufb_mercer)

ggplot(ufb_mercer, aes(x = pop, y = budget_m)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE)

lm(budget_m ~ I(pop / 1000), data = ufb_mercer)   # intercept -12.24, slope 2.38 per thousand residents

# Ewing: predicted -12.24 + 2.38 * 35.858 = 73.1; actual 58.1; residual about -15, below the line.
# Being below the line means spending is below expected, given population. 
# Trenton is the farthest above it.
# Being below the line means spending is above expected, given population. 


# Task 4. Three or More Variables ----------------------------------------------------------------

# ufb_mercer from Task 3: expect 12 rows and 18 columns
dim(ufb_mercer)
names(ufb_mercer)
summary(ufb_mercer)

# Inside aes(): a column, so a legend appears, one color per kind of town
ggplot(ufb_mercer, aes(x = pop, y = budget_m, colour = type)) +
  geom_point()

# Outside aes(): a value, so every point is one color and there is no legend
ggplot(ufb_mercer, aes(x = pop, y = budget_m)) +
  geom_point(colour = "steelblue")

mercer_years <- nj_all |>
  filter(county == "Mercer") |>
  mutate(per_resident = if_else(budget > 0 & pop > 0, per_resident, NA_real_)) |>
  select(town, year, per_resident) |>
  complete(town, year)   # a missing year becomes NA, so the line breaks there

# One row is one Mercer town in one budget year. Expect 120 rows (12 x 10) and 3 columns.
dim(mercer_years)
names(mercer_years)
summary(mercer_years)

ggplot(mercer_years, aes(x = year, y = per_resident)) +
  geom_line() +
  geom_point(size = 0.8) +
  facet_wrap(~ town)

ggplot(mercer_years, aes(x = year, y = per_resident)) +
  geom_line() +
  geom_point(size = 0.8) +
  facet_wrap(~ town, scales = "free_y")

no_village <- nj_2025 |>
  filter(type != "village")

# Expect 561 rows and 18 columns: the three villages are gone
dim(no_village)
names(no_village)
summary(no_village)

ggplot(no_village, aes(y = type, fill = state_plan)) +
  geom_bar(position = "fill")

# The proportions behind the "fill" bars
no_village |>
  count(type, state_plan) |>
  group_by(type) |>
  mutate(prop = round(n / sum(n), 2))


# Task 5. Fix the Key, Then Merge ----------------------------------------------------------------

ufb_mercer <- nj_2025 |>
  filter(county == "Mercer") |>
  select(muni_code, town, pop, budget_m, police_ft)

# One row is one Mercer County town in 2025. Expect 12 rows and 5 columns.
dim(ufb_mercer)
names(ufb_mercer)
summary(ufb_mercer)

tax_mercer <- tax |>
  filter(county_code == "11") |>
  select(district, avg_tax_bill)

# One row is one Mercer County taxing district in 2024. Expect 12 rows and 2 columns.
dim(tax_mercer)
names(tax_mercer)
summary(tax_mercer)

# On the raw names, nothing matches
ufb_mercer |>
  anti_join(tax_mercer, by = c("town" = "district"))   # expect 12 rows

# The repaired key, built by the same rules in both tables
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

# anti_join() both ways
ufb_mercer |>
  anti_join(tax_mercer, by = "key")    # expect 1 row: "princeton boro"

tax_mercer |>
  anti_join(ufb_mercer, by = "key")    # expect 1 row: "princeton"

# The lookup table for what no rule can fix
fixes <- tribble(
  ~key,        ~key_fixed,
  "princeton", "princeton boro"
)

tax_mercer <- tax_mercer |>
  left_join(fixes, by = "key") |>
  mutate(key = coalesce(key_fixed, key)) |>   # the fix, or else the key
  select(-key_fixed)

ufb_mercer |>
  anti_join(tax_mercer, by = "key")    # expect 0 rows

tax_mercer |>
  anti_join(ufb_mercer, by = "key")    # expect 0 rows

# Before the merge, what I expect:
# 1) Rows: ufb_mercer is the left table, so 12 rows in and 12 rows out.
# 2) Columns: 6 + 3 - 1 = 8 (the key is counted once).
# 3) Drops: none either way, after the lookup table.
mercer_merged <- ufb_mercer |>
  left_join(tax_mercer, by = "key")

# Three checks after the merge: expect 12 rows and 8 columns
dim(mercer_merged)
names(mercer_merged)
summary(mercer_merged)

# Statewide, the repaired names repeat across counties (five washington twp), so the key has to
# be the county AND the repaired name: by = c("county", "key").


# Task 6. The Rate, Labeled and Saved ------------------------------------------------------------

# One row is one place. Expect 21 rows and 21 columns.
dim(quickfacts)
names(quickfacts)
summary(quickfacts)

# The two rows that are not towns are the benchmark: set them aside
quickfacts_towns <- quickfacts |>
  filter(!geography %in% c("Mercer County, New Jersey", "New Jersey")) |>
  mutate(
    county = case_when(
      str_detect(geography, "Burlington") ~ "Burlington",
      str_detect(geography, "Middlesex")  ~ "Middlesex",
      str_detect(geography, "Somerset")   ~ "Somerset",
      TRUE ~ "Mercer"      # the places listed without a county are all in Mercer
    ),
    key = geography |>
      word(1, sep = ",") |>
      str_to_lower() |>
      str_squish() |>
      str_replace(" township$", " twp") |>
      str_replace(" borough$", " boro")
  ) |>
  left_join(fixes, by = "key") |>               # Princeton needs the same fix as in Task 5
  mutate(key = coalesce(key_fixed, key)) |>
  select(-key_fixed)

# Expect 19 rows and 23 columns (21 plus county and key)
dim(quickfacts_towns)
names(quickfacts_towns)
summary(quickfacts_towns)

# The statewide merge of Source 1 and Source 2 needs the 14-row lookup table in 07_fixing_keys.R,
# and 09_the_merge.R saves the result as data/nj_merged.csv. Read that instead of redoing it here.
nj_merged <- read_csv(
  "data/nj_merged.csv",
  col_types = cols(muni_code = col_character())
)

# One row is one NJ municipality, Sources 1 and 2 together. Expect 564 rows and 21 columns.
dim(nj_merged)
names(nj_merged)
summary(nj_merged)

# Keep only the key and the columns we need
nj_merged <- nj_merged |>
  select(county, key, town, budget_m, pop_ufb = pop, avg_tax_bill)

# Is county + key really a key? Both of these should return zero rows.
quickfacts_towns |>
  count(county, key) |>
  filter(n > 1)

nj_merged |>
  count(county, key) |>
  filter(n > 1)

# Before the merge, what I expect:
# 1) Rows: quickfacts_towns is the left table, so 19 rows in and 19 rows out.
# 2) Columns: 23 + 6 - 2 = 27 (county and key are counted once).
# 3) Drops: none on the QuickFacts side; 545 on the other (the towns QuickFacts did not download).
quickfacts_towns |>
  anti_join(nj_merged, by = c("county", "key"))   # expect 0 rows

nj_merged |>
  anti_join(quickfacts_towns, by = c("county", "key")) |>
  nrow()                 # expect 545 (564 - 19)

near_tcnj <- quickfacts_towns |>
  left_join(nj_merged, by = c("county", "key"))

# Three checks after the merge: expect 19 rows and 27 columns
dim(near_tcnj)
names(near_tcnj)
summary(near_tcnj)

near_tcnj <- near_tcnj |>
  mutate(
    tax_share = avg_tax_bill / median_hh_income * 100,
    is_ewing = town == "Ewing township"
  )

near_tcnj |>
  select(town, avg_tax_bill, median_hh_income, tax_share) |>
  arrange(desc(tax_share))   # highest Princeton (11.8), lowest Florence (5.3), Ewing 8.9

# The benchmark, from the same two sources: New Jersey's bill over New Jersey's income
9898 / 103556 * 100          # 9.6 percent

tax_share_fig <- ggplot(
  near_tcnj,
  aes(
    x = tax_share,
    y = fct_reorder(town, tax_share),
    fill = is_ewing
  )
) +
  geom_col() +
  geom_vline(
    xintercept = 9.6,
    linetype = "dashed"
  ) +
  scale_fill_manual(
    values = c(`TRUE` = "grey20", `FALSE` = "grey65"),
    guide = "none"
  ) +
  labs(
    title    = "Ewing's tax bill takes a smaller share of income than the NJ average",
    subtitle = "Each bar is one of 19 towns near TCNJ; Ewing in black; the dashed line is New Jersey (9.6%)",
    x        = "Average residential tax bill (2024) as a percent of median household income (2020-2024)",
    y        = NULL,
    caption  = "Sources: NJ Division of Taxation, Average Residential Tax Report, 2024; U.S. Census Bureau, QuickFacts (ACS 2020-2024)"
  )

tax_share_fig

ggsave(
  "output/ewing_vs_neighbors.png",
  tax_share_fig,
  width = 6,
  height = 4
)
