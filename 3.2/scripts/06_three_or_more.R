# scripts/06_three_or_more.R
# Workbook 3.2, Section 4, "Three or More Variables": Figure 14 (a third variable as color, inside
# aes()), Figure 15 (color set outside aes(), and the common mistake), Figures 16 and 17 (small
# multiples with facet_wrap(), fixed and free scales), and Figure 18 (a heatmap with geom_tile()).


# Packages and Load the Data ---------------------------------------------------------------------

library(tidyverse)
library(patchwork)   # puts two plots side by side: a + b

# Every town in every budget year, 2016 to 2025, with the budget in dollars
nj_all <- read_csv(
  "data/nj_2016_2025.csv",
  col_types = cols(muni_code = col_character())   # keep the code as text: "0101", not 101
)

# One row is one town in one budget year. Expect 5,646 rows and 13 columns.
dim(nj_all)
names(nj_all)
summary(nj_all)

# Census QuickFacts for 19 towns near TCNJ, plus Mercer County and New Jersey
quickfacts <- read_csv(
  "data/quickfacts_near_tcnj.csv",
  col_types = cols(fips = col_character())        # the FIPS code is a code, not a number
)

# One row is one place. Expect 21 rows and 21 columns.
dim(quickfacts)
names(quickfacts)
summary(quickfacts)


# The QuickFacts Towns: 19 Towns, Without the Two Rows That Are NOT Towns ------------------------

# One row is one geography as the Census names it. Mercer County and New Jersey are benchmarks,
# not towns, so they come out before anything gets plotted. The county is hiding in the name.
quickfacts_towns <- quickfacts |>
  filter(!geography %in% c("Mercer County, New Jersey", "New Jersey")) |>
  mutate(
    county = case_when(
      str_detect(geography, "Mercer County") ~ "Mercer",
      str_detect(geography, "Burlington County") ~ "Burlington",
      str_detect(geography, "Middlesex County") ~ "Middlesex",
      str_detect(geography, "Somerset County") ~ "Somerset",
      TRUE ~ "Mercer"      # Trenton, Princeton, and Hightstown are listed without a county
    ),
    town = word(geography, 1, sep = ",")
  )

# Expect 19 rows: 21 minus the two benchmark rows
dim(quickfacts_towns)

quickfacts_towns |>
  select(town, county, median_hh_income, median_home_value, mean_commute_min) |>
  print(n = 19)


# Figure 14: A Third Variable, Mapped to Color INSIDE aes() --------------------------------------

# Say: "...map income to x, home value to y, and county to color, and draw one point per row."
# Because county is inside aes(), R picks one color per county and draws a legend.
fig14 <- ggplot(
  quickfacts_towns,
  aes(
    x = median_hh_income,
    y = median_home_value,
    colour = county
  )
) +
  geom_point(size = 2) +
  scale_x_continuous(labels = scales::label_dollar(scale = 1e-3, suffix = "K")) +
  scale_y_continuous(labels = scales::label_dollar(scale = 1e-3, suffix = "K")) +
  labs(
    title = "Home values rise with incomes in the towns near TCNJ",
    subtitle = "Each point is one town within about 30 minutes of campus; color is its county",
    x = "Median household income (2020-2024)",
    y = "Median value of owner-occupied homes",
    colour = "County",
    caption = "Source: U.S. Census Bureau, QuickFacts (ACS 5-year estimates, 2020-2024)"
  ) +
  theme(
    plot.title = element_text(size = 10),
    plot.subtitle = element_text(size = 8),
    plot.caption = element_text(size = 7)
  )

print(fig14)

ggsave(
  "output/figures/fig14_colour_inside_aes.png",
  fig14,
  width = 5.8,
  height = 3.3,
  dpi = 300,
  bg = "white"
)


# Figure 15: Color OUTSIDE aes() Is a Look, Not a Mapping; and the Common Mistake ----------------

outside <- ggplot(quickfacts_towns, aes(x = median_hh_income, y = median_home_value)) +
  geom_point(colour = "steelblue", size = 2) +
  scale_x_continuous(labels = scales::label_dollar(scale = 1e-3, suffix = "K")) +
  scale_y_continuous(labels = scales::label_dollar(scale = 1e-3, suffix = "K")) +
  labs(
    title = "outside aes(): one color",
    x = "Median household income",
    y = "Median home value"
  ) +
  theme(
    plot.title = element_text(family = "mono", size = 7),
    axis.text.x = element_text(size = 6)
  )

mistake <- ggplot(
  quickfacts_towns,
  aes(
    x = median_hh_income,
    y = median_home_value,
    colour = "steelblue"
  )
) +
  geom_point(size = 2) +
  scale_x_continuous(labels = scales::label_dollar(scale = 1e-3, suffix = "K")) +
  scale_y_continuous(labels = scales::label_dollar(scale = 1e-3, suffix = "K")) +
  labs(
    title = "inside aes(): the mistake",
    x = "Median household income",
    y = NULL
  ) +
  theme(
    plot.title = element_text(family = "mono", size = 7),
    axis.text.x = element_text(size = 6)
  )

fig15 <- outside + mistake

print(fig15)

ggsave(
  "output/figures/fig15_colour_outside_aes.png",
  fig15,
  width = 6.4,
  height = 2.6,
  dpi = 300,
  bg = "white"
)

# size is another aesthetic: a fourth variable. (Area, so the reader judges it roughly: 3.1.)
ggplot(
  quickfacts_towns,
  aes(
    x = median_hh_income,
    y = median_home_value,
    colour = county,
    size = pop_2025_est
  )
) +
  geom_point(alpha = 0.7)


# Figures 16 and 17: Small Multiples With facet_wrap() -------------------------------------------

# One panel per town, every panel on the same axes (fixed scales) or on its own (free scales).
# complete() adds a row for every town and year, with NA where no budget was filed, so geom_line()
# breaks at a missing year instead of drawing a straight line across it.
mercer_years <- nj_all |>
  filter(county == "Mercer") |>
  mutate(
    per_resident = if_else(budget > 0 & pop > 0, budget / pop, NA_real_),
    town = town |>
      str_replace(" township", " twp") |>
      str_replace(" borough", " boro")
  ) |>
  select(town, year, per_resident) |>
  complete(town, year)

# One row is one Mercer town in one budget year. Expect 120 rows (12 towns x 10 years) and 3 columns.
dim(mercer_years)

fig16 <- ggplot(mercer_years, aes(x = year, y = per_resident)) +
  geom_line() +
  geom_point(size = 0.8) +      # a year with no neighbor (Hightstown 2025) still shows
  facet_wrap(~ town) +
  scale_x_continuous(breaks = c(2016, 2020, 2024)) +
  scale_y_continuous(labels = scales::dollar) +
  labs(
    title = "facet_wrap(~ town): fixed scales",
    subtitle = "General budget per resident, 2016 to 2025",
    x = "Budget year",
    y = "Budget per resident",
    caption = "Source: NJ DCA, User Friendly Budget Database, 2016 to 2025"
  ) +
  theme(
    plot.title = element_text(family = "mono", size = 9),
    plot.subtitle = element_text(size = 8),
    strip.text = element_text(size = 7),
    axis.text = element_text(size = 6),
    plot.caption = element_text(size = 7)
  )

print(fig16)

ggsave(
  "output/figures/fig16_facets_fixed.png",
  fig16,
  width = 6.0,
  height = 4.0,
  dpi = 300,
  bg = "white"
)

fig17 <- ggplot(mercer_years, aes(x = year, y = per_resident)) +
  geom_line() +
  geom_point(size = 0.8) +
  facet_wrap(~ town, scales = "free_y") +
  scale_x_continuous(breaks = c(2016, 2020, 2024)) +
  scale_y_continuous(labels = scales::dollar) +
  labs(
    title = "facet_wrap(~ town, scales = \"free_y\")",
    subtitle = "The same 12 lines; every panel now has its own y-axis",
    x = "Budget year",
    y = "Budget per resident"
  ) +
  theme(
    plot.title = element_text(family = "mono", size = 9),
    plot.subtitle = element_text(size = 8),
    strip.text = element_text(size = 7),
    axis.text = element_text(size = 6)
  )

print(fig17)

ggsave(
  "output/figures/fig17_facets_free.png",
  fig17,
  width = 6.0,
  height = 4.0,
  dpi = 300,
  bg = "white"
)


# Figure 18: A Heatmap With geom_tile() ----------------------------------------------------------

# The table behind it: one row per town and year, with the number that becomes the color.
heat <- mercer_years |>
  filter(!is.na(per_resident))     # a missing year stays a white gap

# Expect 115 rows: 120 town-years minus the 5 with no budget filed
dim(heat)

heat |>
  filter(town %in% c("Ewing twp", "Lawrence twp", "Trenton city"), year %in% 2023:2025) |>
  mutate(per_resident = round(per_resident)) |>
  pivot_wider(names_from = year, values_from = per_resident)

fig18 <- ggplot(
  heat,
  aes(
    x = year,
    y = fct_rev(town),             # A at the top
    fill = per_resident
  )
) +
  geom_tile(colour = "white") +
  scale_fill_gradient(low = "grey92", high = "grey15", labels = scales::dollar) +
  scale_x_continuous(breaks = 2016:2025, expand = c(0, 0)) +
  labs(
    title = "Every Mercer town budgets more per resident in 2025 than in 2016",
    subtitle = "One tile per town and budget year; darker is more. White: no budget filed",
    x = "Budget year",
    y = NULL,
    fill = "Budget per\nresident",
    caption = "Source: NJ DCA, User Friendly Budget Database, 2016 to 2025"
  ) +
  theme(
    plot.title = element_text(size = 10),
    plot.subtitle = element_text(size = 7),
    axis.text.x = element_text(size = 7),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 8),
    plot.caption = element_text(size = 7),
    panel.background = element_rect(fill = "white"),
    panel.grid = element_blank()
  )

print(fig18)

ggsave(
  "output/figures/fig18_heatmap.png",
  fig18,
  width = 6.0,
  height = 3.4,
  dpi = 300,
  bg = "white"
)

# Where a value falls on the color scale: (value - min) / (max - min)
range(heat$per_resident)
