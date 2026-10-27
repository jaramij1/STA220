# scripts/10_rates_from_two_sources.R
# Workbook 3.2, Section 6, "Rates From Two Sources": a rate whose numerator is in one source and
# whose denominator is in another, the state as the benchmark, Figure 20 (the tax bill as a share
# of income for the towns near TCNJ, Ewing highlighted), Figure 21 (police officers per 1,000
# residents with two different denominators), and the merged table for the dashboard example.


# Packages and Load the Data ---------------------------------------------------------------------

library(tidyverse)

# Made by 09_the_merge.R: Sources 1 and 2, one row per town
nj_merged <- read_csv(
  "data/nj_merged.csv",
  col_types = cols(muni_code = col_character())   # keep the code as text: "0101", not 101
)

# One row is one NJ municipality. Expect 564 rows and 21 columns.
dim(nj_merged)
names(nj_merged)
summary(nj_merged)

# Source 3: Census QuickFacts for 19 towns near TCNJ, plus Mercer County and New Jersey
quickfacts <- read_csv(
  "data/quickfacts_near_tcnj.csv",
  col_types = cols(fips = col_character())
)

# One row is one place. Expect 21 rows and 21 columns.
dim(quickfacts)
names(quickfacts)
summary(quickfacts)


# Source 3, Repaired: One Row per Town, With a Key That Matches the UFB's ------------------------

# The two rows that are not towns are the benchmark: keep them in a table of their own
benchmarks <- quickfacts |>
  filter(geography %in% c("Mercer County, New Jersey", "New Jersey"))

# The name is "Ewing township, Mercer County, New Jersey". Cut it at the first comma, then the same
# repairs as 07_fixing_keys.R. Three towns are listed without a county (they are Census "places").
quickfacts_towns <- quickfacts |>
  filter(!geography %in% c("Mercer County, New Jersey", "New Jersey")) |>
  mutate(
    county = case_when(
      str_detect(geography, "Burlington County") ~ "Burlington",
      str_detect(geography, "Middlesex County")  ~ "Middlesex",
      str_detect(geography, "Somerset County")   ~ "Somerset",
      TRUE ~ "Mercer"
    ),
    key = geography |>
      word(1, sep = ",") |>
      str_to_lower() |>
      str_squish() |>
      str_replace(" township$", " twp") |>
      str_replace(" borough$", " boro") |>
      str_replace("^princeton$", "princeton boro")     # the one leftover, fixed by hand
  )

quickfacts_towns |>
  select(geography, county, key)

# Before the merge, what I expect:
# 1) Rows: quickfacts_towns is the left table, so 19 rows in and 19 rows out.
# 2) Drops: none on the QuickFacts side; on the UFB side, every town QuickFacts did not download.
quickfacts_towns |>
  anti_join(nj_merged, by = c("county", "key")) |>
  select(geography)      # expect 0 rows

nj_merged |>
  filter(county == "Mercer") |>
  anti_join(quickfacts_towns, by = c("county", "key")) |>
  select(town)           # Hopewell borough and Pennington borough (under 5,000 residents)

near_tcnj <- quickfacts_towns |>
  left_join(
    nj_merged |>
      select(
        county, key, muni_code, town, pop_ufb = pop, budget_m, levy_m, police_ft,
        ft_employees, debt_per_resident, avg_tax_bill
      ),
    by = c("county", "key")
  )

# Three checks after the merge: expect 19 rows and 32 columns
dim(near_tcnj)
names(near_tcnj)
summary(near_tcnj)

write_csv(near_tcnj, "data/near_tcnj.csv")


# The Rate: the Tax Bill (Source 2) as a Share of Income (Source 3) ------------------------------

# Ewing: 8,096 / 91,267 = 0.0887, so 8.9 percent of the median household's income
8096 / 91267 * 100

# near_tcnj after the merge: Sources 1, 2, and 3 in one row per town
near_tcnj <- near_tcnj |>
  mutate(
    tax_share = avg_tax_bill / median_hh_income * 100,
    police_per_1000 = police_ft / pop_2025_est * 1000
  )

near_tcnj |>
  select(town, avg_tax_bill, median_hh_income, tax_share) |>
  arrange(tax_share) |>
  print(n = 19)

# The benchmark: the state. Both numbers exist for New Jersey as a whole.
nj_bill <- 9898          # STATE AVERAGE in the 2024 report

nj_income <- benchmarks |>
  filter(geography == "New Jersey") |>
  pull(median_hh_income)

nj_bill / nj_income * 100                                   # 9.6 percent


# Figure 20: One Bar per Town, Sorted, the Practice Town Highlighted -----------------------------

# A third variable, is_ewing, is mapped to fill INSIDE aes(): that is how one bar gets its own color.
near_tcnj <- near_tcnj |>
  mutate(is_ewing = town == "Ewing township")

fig20 <- ggplot(
  near_tcnj,
  aes(
    x = tax_share,
    y = fct_reorder(town, tax_share),
    fill = is_ewing
  )
) +
  geom_col() +
  geom_vline(xintercept = nj_bill / nj_income * 100, linetype = "dashed") +
  annotate("text", x = 9.7, y = 1.3, label = "New Jersey: 9.6%", hjust = 0, size = 2.8) +
  scale_fill_manual(values = c(`TRUE` = "grey20", `FALSE` = "grey65"), guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.06))) +
  labs(
    title    = "Ewing's tax bill takes a smaller bite of income than the NJ average",
    subtitle = "Tax bill (2024) as a percent of median household income (2020-2024); 19 towns near TCNJ",
    x        = "Average tax bill as a percent of median household income",
    y        = NULL,
    caption  = "Sources: NJ Division of Taxation, Average Residential Tax Report, 2024; U.S. Census Bureau, QuickFacts (ACS 2020-2024)"
  ) +
  theme(
    plot.title = element_text(size = 9.5),
    plot.subtitle = element_text(size = 7),
    plot.caption = element_text(size = 6.5),
    axis.text.y = element_text(size = 7),
    plot.margin = margin(5.5, 14, 5.5, 5.5)      # room for the last axis label, 12.5
  )

print(fig20)

ggsave(
  "output/figures/fig20_tax_share.png",
  fig20,
  width = 6.0,
  height = 3.8,
  dpi = 300,
  bg = "white"
)


# Figure 21: The Denominator Matters. Police per 1,000 Residents, Two Population Sources --------

# The UFB's population (the number its 2025 sheet prints) and QuickFacts' (July 2025) disagree, so
# the same 87 officers give two different rates for Ewing. Say which denominator you used.
rates <- near_tcnj |>
  filter(!is.na(police_ft), police_ft > 0) |>
  mutate(
    per_1000_ufb    = police_ft / pop_ufb * 1000,
    per_1000_census = police_ft / pop_2025_est * 1000
  )

rates |>
  select(town, police_ft, pop_ufb, pop_2025_est, per_1000_ufb, per_1000_census) |>
  arrange(desc(per_1000_ufb))

# Two columns of rates become one column, with a second column saying which denominator
rates_long <- rates |>
  select(town, `UFB population` = per_1000_ufb, `Census 2025 estimate` = per_1000_census) |>
  pivot_longer(-town, names_to = "denominator", values_to = "per_1000")

fig21 <- ggplot(
  rates_long,
  aes(
    x = per_1000,
    y = fct_reorder(town, per_1000),
    colour = denominator
  )
) +
  geom_point(size = 2) +
  scale_colour_manual(values = c(`UFB population` = "grey20", `Census 2025 estimate` = "grey60")) +
  labs(
    title = "The same officers, two populations, two rates",
    subtitle = "Full-time police officers per 1,000 residents, 2025; towns that reported a force",
    x = "Officers per 1,000 residents",
    y = NULL,
    colour = "Denominator",
    caption = "Sources: NJ DCA, UFB Database, 2025; U.S. Census Bureau, QuickFacts (July 2025 estimate)"
  ) +
  theme(
    plot.title = element_text(size = 10),
    plot.subtitle = element_text(size = 7.5),
    plot.caption = element_text(size = 6.5),
    axis.text.y = element_text(size = 7),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 8)
  )

print(fig21)

ggsave(
  "output/figures/fig21_two_denominators.png",
  fig21,
  width = 6.0,
  height = 3.6,
  dpi = 300,
  bg = "white"
)
