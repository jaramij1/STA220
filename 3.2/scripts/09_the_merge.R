# scripts/09_the_merge.R
# Workbook 3.2, Section 6, "The Merge: left_join() and anti_join()": the Mercer merge with a
# prediction first, Figure 19 (one row from each source becomes one row with the columns of both),
# the statewide merge every later script starts from, and the paired key (town and year together).


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

# Made by 07_fixing_keys.R: every town's code, county, name, and repaired key
ufb_keyed <- read_csv(
  "data/nj_2025_keyed.csv",
  col_types = cols(muni_code = col_character())
)

# Expect 564 rows and 4 columns.
dim(ufb_keyed)
names(ufb_keyed)
summary(ufb_keyed)

# Made by 07_fixing_keys.R: every 2024 tax bill, with the county and the repaired key
tax_keyed <- read_csv("data/tax_bill_2024_keyed.csv")

# Expect 564 rows and 4 columns.
dim(tax_keyed)
names(tax_keyed)
summary(tax_keyed)


# The Mercer Merge: Predict, Then Run ------------------------------------------------------------

ufb_mercer <- nj_2025 |>
  filter(county == "Mercer") |>
  left_join(select(ufb_keyed, muni_code, key), by = "muni_code") |>
  select(muni_code, town, key, pop, budget_m, police_ft)

tax_mercer <- tax_keyed |>
  filter(county == "Mercer") |>
  select(key, district, avg_tax_bill)

ufb_mercer   # 12 rows and 6 columns

tax_mercer   # 12 rows and 3 columns

# Before the merge, what I expect:
# 1) Rows: ufb_mercer is the left table, so 12 rows in and 12 rows out.
# 2) Columns: 6 + 3 - 1 = 8 (the key is counted once).
# 3) Drops: none either way (07_fixing_keys.R repaired Princeton).
anti_join(ufb_mercer, tax_mercer, by = "key")   # expect 0 rows

anti_join(tax_mercer, ufb_mercer, by = "key")   # expect 0 rows

# Say: "Start with ufb_mercer, add the columns of tax_mercer, matching rows by key, and save it
# as mercer_merged."
mercer_merged <- left_join(ufb_mercer, tax_mercer, by = "key")

# Three checks after the merge: expect 12 rows and 8 columns
dim(mercer_merged)
names(mercer_merged)
summary(mercer_merged)


# Figure 19: The Merge, Drawn With the Tables Themselves -----------------------------------------

# (Drawing code you have not seen; the point is the picture, not the code.)
show_tbl <- function(df, title, x0, y0, w, label_size = 2.4) {

  df <- df |>
    mutate(across(everything(), as.character))

  body <- df |>
    mutate(row = row_number()) |>
    pivot_longer(-row, names_to = "name", values_to = "txt") |>
    mutate(col = match(name, names(df)), bold = FALSE) |>
    select(row, col, txt, bold)

  cells <- bind_rows(
    tibble(row = 0, col = seq_along(df), txt = names(df), bold = TRUE),
    body
  )

  list(
    tibble(
      x = x0 + (cells$col - 1) * w,
      y = y0 - cells$row * 0.55,
      txt = cells$txt,
      bold = cells$bold,
      hl = cells$row == 2 & !cells$bold
    ),
    tibble(x = x0, y = y0 + 0.4, txt = title)
  )
}

left4 <- ufb_mercer |>
  slice(1:4) |>
  select(key, pop, budget_m)

right4 <- tax_mercer |>
  slice(1:4) |>
  select(key, avg_tax_bill)

out4 <- left_join(left4, right4, by = "key")

L <- show_tbl(left4, "ufb_mercer (Source 1)", 0, 10, 2.0)

R <- show_tbl(right4, "tax_mercer (Source 2)", 7.6, 10, 2.3)

O <- show_tbl(out4, "left_join(ufb_mercer, tax_mercer, by = \"key\")", 1.8, 5.4, 2.0)

cells  <- bind_rows(L[[1]], R[[1]], O[[1]])

titles <- bind_rows(L[[2]], R[[2]], O[[2]])

fig19 <- ggplot() +
  geom_tile(
    data = filter(cells, hl),
    aes(x = x + 0.8, y = y),
    width = 1.9,
    height = 0.5,
    fill = "grey88"
  ) +
  geom_text(
    data = cells,
    aes(x = x, y = y, label = txt, fontface = if_else(bold, "bold", "plain")),
    hjust = 0,
    size = 2.4
  ) +
  geom_text(
    data = titles,
    aes(x = x, y = y, label = txt),
    hjust = 0,
    size = 2.8,
    family = "mono"
  ) +
  annotate(
    "segment",
    x = c(3, 8.5), xend = c(5, 6.5),
    y = c(7.1, 7.1), yend = c(6.1, 6.1),
    arrow = arrow(length = unit(0.12, "cm")),
    colour = "grey40"
  ) +
  annotate("text", x = 5.8, y = 2.3, label = "The key is in both tables, so \"ewing twp\" finds \"ewing twp\".", size = 2.6) +
  xlim(-0.2, 12.2) +
  ylim(2, 10.6) +
  theme_void()

print(fig19)

ggsave(
  "output/figures/fig19_merge.png",
  fig19,
  width = 6.0,
  height = 3.0,
  dpi = 300,
  bg = "white"
)


# The Statewide Merge, on County + Repaired Name -------------------------------------------------

# nj_keyed is nj_2025 plus the repaired key: 564 rows, 19 columns (county is one of them).
nj_keyed <- nj_2025 |>
  left_join(select(ufb_keyed, muni_code, key), by = "muni_code")

dim(nj_keyed)

# Before the merge, what I expect:
# 1) Rows: 564 in and 564 out.
# 2) Columns: 19 + 4 - 2 = 21 (county and key are counted once).
# 3) Drops: none either way.
nj_keyed |>
  anti_join(tax_keyed, by = c("county", "key")) |>
  nrow()                 # expect 0

tax_keyed |>
  anti_join(nj_keyed, by = c("county", "key")) |>
  nrow()                 # expect 0

nj_merged <- nj_keyed |>
  left_join(tax_keyed, by = c("county", "key")) |>
  mutate(avg_tax_bill = na_if(avg_tax_bill, 0))      # Audubon Park's $0 is not a tax bill (2.4)

# Three checks after the merge: expect 564 rows and 21 columns, and 1 NA in avg_tax_bill (Audubon Park)
dim(nj_merged)
names(nj_merged)
summary(nj_merged)

write_csv(nj_merged, "data/nj_merged.csv")

# The mistake: leave the county out of the key. Twelve repaired names repeat across counties
# (five washington twp), so rows multiply and both tables' county columns come along as .x and .y
wrong <- left_join(nj_keyed, tax_keyed, by = "key")  # many-to-many warning

dim(wrong)                                           # 620 by 22

names(wrong) |>
  str_subset("county")                               # "county.x" "county.y"


# The Paired Key: Town AND Year ------------------------------------------------------------------

# Ewing's tax bill by year (Source 2, 2016 to 2024) joined to Ewing's budget by year (Source 1).
# Leave out the year and every budget row matches every tax row for the town: 10 x 9 = 90 rows.
mercer_tax_years <- read_csv(
  "data/mercer_tax_bill_2016_2024.csv",
  col_types = cols(
    county_code = col_character(),
    district_code = col_character()
  )
)

# One row is one Mercer town in one tax year. Expect 108 rows (12 towns x 9 years) and 5 columns.
dim(mercer_tax_years)
names(mercer_tax_years)
summary(mercer_tax_years)

ewing_years <- read_csv("data/ewing.csv")

# One row is one of Ewing's budget years. Expect 10 rows and 6 columns.
dim(ewing_years)
names(ewing_years)
summary(ewing_years)

ewing_tax <- mercer_tax_years |>
  filter(district == "EWING TWP") |>
  select(year = tax_year, avg_tax_bill)

ewing_budget <- ewing_years |>
  select(year, budget_m, pop, per_resident)   # the Source 1 columns of the ewing table

ewing <- left_join(ewing_budget, ewing_tax, by = "year")

# Three checks after the merge: expect 10 rows and 5 columns; 2025 gets NA (no 2025 report is read)
dim(ewing)
names(ewing)
summary(ewing)

ewing                    # the ewing table printed in the workbook

# The wrong way, for the record: a cross join pairs every budget row with every tax row
ewing_budget |>
  cross_join(rename(ewing_tax, tax_year = year)) |>
  nrow()                 # 90 rows
