# scripts/13_module_practice.R
# Workbook 3.2, "Module 3.2 Practice": Figure 23 (a graphic to describe: the 2024 average tax bill
# in the five counties around TCNJ, one box per county), Figure 24 (a graphic to critique: counts
# where proportions belong), and the blank grids for the by-hand questions about the made-up
# permits table.


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

# MADE UP: one month of building permits
permits <- read_csv("data/permits.csv")

# One row should be one permit. Expect 16 rows and 3 columns.
dim(permits)
names(permits)
summary(permits)


# The Permits Table: the Repeat, the Frequency Table, the Sorted Costs ---------------------------

permits |>
  count(permit_id) |>
  filter(n > 1)          # 1 row: P-110, twice

permits_clean <- permits |>
  distinct()

dim(permits_clean)       # 15 rows

permits_clean |>
  count(type) |>
  mutate(prop = round(n / sum(n), 2))

sort(permits_clean$cost_k)


# Figure 23: A Graphic to Describe ---------------------------------------------------------------

five_counties <- nj_merged |>
  filter(
    county %in% c("Mercer", "Burlington", "Middlesex", "Somerset", "Hunterdon"),
    !is.na(avg_tax_bill)
  )

five_counties |>
  group_by(county) |>
  summarize(
    towns = n(),
    median = median(avg_tax_bill),
    max = max(avg_tax_bill)
  )

fig23 <- ggplot(
  five_counties,
  aes(
    x = avg_tax_bill,
    y = fct_reorder(county, avg_tax_bill)
  )
) +
  geom_boxplot() +
  scale_x_continuous(labels = scales::dollar) +
  labs(
    title    = "Mercer County's tax bills are the most spread out of the five counties around TCNJ",
    subtitle = "One box per county; each box summarizes the average residential tax bill of that county's towns, 2024",
    x        = "Average residential property tax bill, 2024",
    y        = NULL,
    caption  = "Source: NJ Division of Taxation, MOD IV Average Residential Tax Report, 2024"
  ) +
  theme(
    plot.title = element_text(size = 9.5),
    plot.subtitle = element_text(size = 7),
    plot.caption = element_text(size = 7)
  )

print(fig23)

ggsave(
  "output/figures/fig23_describe.png",
  fig23,
  width = 6.0,
  height = 3.0,
  dpi = 300,
  bg = "white"
)


# Figure 24: A Graphic to Critique ---------------------------------------------------------------

# Counts of towns by kind and health-plan answer, dodged. The title reads the tallest bar as the
# biggest share. It is not: there are more boroughs than anything else.
no_na <- nj_merged |>
  filter(!is.na(state_plan), type != "village")

no_na |>
  count(type, state_plan) |>
  group_by(type) |>
  mutate(prop = round(n / sum(n), 2))

fig24 <- ggplot(no_na, aes(x = type, fill = state_plan)) +
  geom_bar(position = "dodge") +
  scale_fill_grey(start = 0.25, end = 0.7) +
  labs(
    title = "BOROUGHS are by far the biggest fans of the state health plan",
    x = NULL,
    y = "Towns",
    fill = "On the state plan?"
  ) +
  theme(plot.title = element_text(size = 10, face = "bold"))

print(fig24)

ggsave(
  "output/figures/fig24_critique.png",
  fig24,
  width = 5.2,
  height = 2.8,
  dpi = 300,
  bg = "white"
)


# The Blank Grids for the Permits Questions ------------------------------------------------------

grid_bars_5 <- ggplot() +
  scale_x_discrete(limits = c("", " ", "  ", "   ", "    ")) +
  scale_y_continuous(breaks = 0:6, limits = c(0, 6), expand = c(0, 0)) +
  labs(
    x = "type (write the kinds in, most common first)",
    y = "Number of permits"
  ) +
  theme_bw() +
  theme(panel.grid.minor = element_blank())

ggsave(
  "output/figures/grid_bars_5.png",
  grid_bars_5,
  width = 4.2,
  height = 2.3,
  dpi = 300,
  bg = "white"
)

grid_hist_cost <- ggplot() +
  scale_x_continuous(breaks = seq(0, 150, 10), limits = c(0, 150), expand = c(0, 0)) +
  scale_y_continuous(breaks = 0:6, limits = c(0, 6), expand = c(0, 0)) +
  labs(
    x = "Estimated cost ($ thousands), bins of 10",
    y = "Number of permits"
  ) +
  theme_bw() +
  theme(
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(size = 7),
    plot.margin = margin(5.5, 16, 5.5, 5.5)     # room for the last tick label
  )

ggsave(
  "output/figures/grid_histogram_cost.png",
  grid_hist_cost,
  width = 6.2,
  height = 2.6,
  dpi = 300,
  bg = "white"
)
