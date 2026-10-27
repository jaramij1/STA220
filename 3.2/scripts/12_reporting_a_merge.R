# scripts/12_reporting_a_merge.R
# Workbook 3.2, Section 6, "Reporting a Merge": the numbers a merge report needs (rows before and
# after, how many matched, what did not and why), and the dashboard example: Figure 22 (commute
# time against the tax bill for the towns near TCNJ, a few towns labeled).


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

# Made by 10_rates_from_two_sources.R: Sources 1, 2, and 3, one row per town near TCNJ
near_tcnj <- read_csv(
  "data/near_tcnj.csv",
  col_types = cols(
    muni_code = col_character(),
    fips = col_character()
  )
)

# One row is one town near TCNJ. Expect 19 rows and 32 columns.
dim(near_tcnj)
names(near_tcnj)
summary(near_tcnj)

quickfacts <- read_csv(
  "data/quickfacts_near_tcnj.csv",
  col_types = cols(fips = col_character())
)

# One row is one place. Expect 21 rows and 21 columns.
dim(quickfacts)
names(quickfacts)
summary(quickfacts)


# The Merge Report, in Numbers -------------------------------------------------------------------

# Source 1 (UFB, 2025) x Source 2 (Taxation, 2024), on county + repaired name:
#   rows before: 564 and 564; rows after: 564
#   matched: 550 on the repaired names, 14 more after a 14-row lookup table; 0 unmatched either way
#   still missing after the merge: 14 towns with no 2025 budget; Audubon Park's $0 bill set to NA
sum(is.na(nj_merged$budget_m))

sum(is.na(nj_merged$avg_tax_bill))

# Source 3 (QuickFacts) x the merged table, on county + repaired name:
#   rows before: 19 towns (2 benchmark rows set aside); rows after: 19; matched: 19 of 19
#   not in QuickFacts: Hopewell borough and Pennington borough (under 5,000 residents), by design
nrow(near_tcnj)


# Figure 22: The Dashboard Figure. Two Sources on the Axes, a Third as Color ---------------------

nj_avg_bill <- 9898

nj_commute <- quickfacts |>
  filter(geography == "New Jersey") |>
  pull(mean_commute_min)

# The five towns that get a label. West Windsor's label goes to the left, clear of Montgomery's point.
labeled <- near_tcnj |>
  filter(town %in% c("Ewing township", "Princeton borough", "Trenton city", "Florence township", "West Windsor township")) |>
  mutate(
    h = if_else(town == "West Windsor township", 1.15, 0.5),
    v = if_else(town == "West Windsor township", 0.5, -0.9)
  )

fig22 <- ggplot(
  near_tcnj,
  aes(
    x = mean_commute_min,
    y = avg_tax_bill,
    colour = county
  )
) +
  geom_hline(yintercept = nj_avg_bill, linetype = "dashed", colour = "grey50") +
  geom_vline(xintercept = nj_commute, linetype = "dashed", colour = "grey50") +
  geom_point(size = 2.2) +
  geom_text(
    data = labeled,
    aes(
      label = word(town, 1, 2) |>
        str_remove(" township| borough| city"),
      hjust = h,
      vjust = v
    ),
    size = 2.6,
    show.legend = FALSE
  ) +
  annotate("text", x = 38.8, y = nj_avg_bill - 600, label = "NJ average bill: $9,898", hjust = 1, size = 2.5, colour = "grey30") +
  annotate("text", x = nj_commute + 0.2, y = 22500, label = "NJ mean commute: 30.5 min", hjust = 0, size = 2.5, colour = "grey30") +
  scale_y_continuous(labels = scales::dollar, expand = expansion(mult = c(0.05, 0.12))) +
  scale_colour_grey(start = 0.1, end = 0.7) +
  labs(
    title    = "Ewing pairs a short commute with a below-average tax bill",
    subtitle = "Each point is one of 19 towns within about 30 minutes of campus; the dashed lines are New Jersey as a whole",
    x        = "Mean travel time to work, residents' commutes (minutes, 2020-2024)",
    y        = "Average residential property tax bill (2024)",
    colour   = "County",
    caption  = "Sources: U.S. Census Bureau, QuickFacts (ACS 2020-2024); NJ Division of Taxation (2024 tax bills)"
  ) +
  theme(
    plot.title = element_text(size = 9),
    plot.subtitle = element_text(size = 7),
    plot.caption = element_text(size = 6.5),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 8)
  )

print(fig22)

ggsave(
  "output/figures/fig22_dashboard_scatter.png",
  fig22,
  width = 6.2,
  height = 3.8,
  dpi = 300,
  bg = "white"
)
