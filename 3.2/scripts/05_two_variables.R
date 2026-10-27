# scripts/05_two_variables.R
# Workbook 3.2, Section 3, "Two Variables": Figure 8 (two numbers: a scatterplot with the line R fits),
# percent change and the benchmark table with group_by() and summarize(), Figure 9 (Ewing against
# the median NJ town, two lines from two tables), Figure 10 (one benchmark value with geom_hline()),
# Figure 11 (a category and a number: sorted bars with a benchmark), Figure 12 (one boxplot per
# group), Figure 13 (two categories: stack, dodge, fill), and the blank grid for the practice.


# Packages and Load the Data ---------------------------------------------------------------------

library(tidyverse)
library(patchwork)   # puts plots side by side: a + b + c

nj_2025 <- read_csv(
  "data/nj_2025.csv",
  col_types = cols(muni_code = col_character())   # keep the code as text: "0101", not 101
)

# One row is one NJ municipality's 2025 budget. Expect 564 rows and 18 columns.
dim(nj_2025)
names(nj_2025)
summary(nj_2025)

# Every town in every budget year, 2016 to 2025, with the budget in dollars
nj_all <- read_csv(
  "data/nj_2016_2025.csv",
  col_types = cols(muni_code = col_character())
)

# One row is one town in one budget year. Expect 5,646 rows and 13 columns.
dim(nj_all)
names(nj_all)
summary(nj_all)

ufb_mercer <- read_csv("data/ufb_mercer.csv")

# One row is one Mercer County town in 2025. Expect 12 rows and 12 columns.
dim(ufb_mercer)
names(ufb_mercer)
summary(ufb_mercer)

ewing <- read_csv("data/ewing.csv")

# One row is one of Ewing's budget years. Expect 10 rows and 6 columns.
dim(ewing)
names(ewing)
summary(ewing)


# Two Numbers: Figure 8, a Scatterplot With a Line Through It ------------------------------------

# Say: "Start a plot with ufb_mercer, map population to x and the budget to y, draw one point for
# each row, and then draw the straight line that fits the points best."
fig08 <- ggplot(ufb_mercer, aes(x = pop, y = budget_m)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE)     # the least-squares line: lm is short for linear model

print(fig08)

ggsave(
  "output/figures/fig08_mercer_scatter_line.png",
  fig08,
  width = 4.0,
  height = 2.6,
  dpi = 300,
  bg = "white"
)

# The line as numbers: lm() prints the intercept and the slope
mercer_line <- lm(budget_m ~ I(pop / 1000), data = ufb_mercer)

mercer_line

# A residual is actual minus predicted, and it is often the finding
ufb_mercer |>
  mutate(
    predicted = coef(mercer_line)[1] + coef(mercer_line)[2] * pop / 1000,
    residual  = budget_m - predicted
  ) |>
  select(town, pop, budget_m, predicted, residual) |>
  arrange(desc(residual))


# A Number Over Time: Percent Change -------------------------------------------------------------

# A percent change is the change divided by where you started, times 100.
(58.1 - 43.3) / 43.3 * 100            # Ewing's budget grew 34.2 percent from 2016 to 2025

(1621 - 1216) / 1216 * 100            # per resident, 33.3 percent

# In R it begins with filter(year %in% c(2016, 2025)): a percent change needs exactly two rows
ewing |>
  filter(year %in% c(2016, 2025))


# The Benchmark Table: One Row per Year, With group_by() and summarize() -------------------------

# Say: "Start with nj_all, and then keep the rows with a budget and a population, and then add a
# column for the budget per resident, and then group the rows by year, and then collapse each group
# to one row with the number of towns and the median budget per resident."
state_by_year <- nj_all |>
  filter(!is.na(budget), !is.na(pop), budget > 0, pop > 0) |>
  mutate(per_resident = budget / pop) |>
  group_by(year) |>
  summarize(
    towns = n(),
    median_per_resident = median(per_resident)
  )

state_by_year

(1679 - 1319) / 1319 * 100            # the median town's budget per resident grew 27.3 percent


# Figure 9: Ewing Against the State, Two Lines From Two Tables -----------------------------------

# The first geom_line() uses the plot's data, ewing. The second brings its own table and its own
# mapping, because the benchmark lives in a different table with different column names.
fig09 <- ggplot(ewing, aes(x = year, y = per_resident)) +
  geom_line() +
  geom_point() +
  geom_line(
    data = state_by_year,
    aes(x = year, y = median_per_resident),
    linetype = "dashed"
  ) +
  annotate("text", x = 2016.1, y = 1405, label = "median NJ town", hjust = 0, size = 3, colour = "grey30") +
  annotate("text", x = 2016.1, y = 1175, label = "Ewing", hjust = 0, size = 3, fontface = "bold") +
  scale_x_continuous(breaks = seq(2016, 2025, 3)) +
  scale_y_continuous(labels = scales::dollar) +
  labs(
    title    = "Ewing budgets a little less per resident than the typical NJ town",
    subtitle = "General budget per resident, 2016 to 2025",
    x        = "Budget year",
    y        = "General budget per resident",
    caption  = "Source: NJ DCA, User Friendly Budget Database, 2016 to 2025 (budgets, and the population each sheet prints)"
  ) +
  theme(
    plot.title = element_text(size = 10.5),
    plot.subtitle = element_text(size = 8.5),
    plot.caption = element_text(size = 6.5)
  )

print(fig09)

ggsave(
  "output/figures/fig09_ewing_vs_state.png",
  fig09,
  width = 5.6,
  height = 3.3,
  dpi = 300,
  bg = "white"
)


# Figure 10: The Same Benchmark as a Single Reference Line ---------------------------------------

fig10 <- ggplot(ewing, aes(x = year, y = per_resident)) +
  geom_line() +
  geom_point() +
  geom_hline(yintercept = 1679, linetype = "dashed") +
  annotate("text", x = 2016, y = 1715, label = "NJ median town, 2025: $1,679", hjust = 0, size = 3, colour = "grey30") +
  scale_x_continuous(breaks = seq(2016, 2025, 3)) +
  scale_y_continuous(labels = scales::dollar) +
  labs(
    x = "Budget year",
    y = "General budget per resident"
  )

print(fig10)

ggsave(
  "output/figures/fig10_ewing_hline.png",
  fig10,
  width = 4.6,
  height = 2.6,
  dpi = 300,
  bg = "white"
)

# What the rate hides: the population the UFB printed fell by 2,800 in 2023
ewing |>
  mutate(
    budget_change = round((budget_m / lag(budget_m) - 1) * 100, 1),
    pop_change    = round((pop / lag(pop) - 1) * 100, 1)
  ) |>
  filter(year %in% 2022:2024)


# The Blank Grid for the Over-Time Practice ------------------------------------------------------

grid_over_time <- ggplot() +
  scale_x_continuous(breaks = 2016:2025, limits = c(2015.6, 2025.4), expand = c(0, 0)) +
  scale_y_continuous(
    breaks = seq(1100, 1800, 100),
    limits = c(1100, 1800),
    expand = c(0, 0),
    labels = scales::dollar
  ) +
  labs(
    x = "Budget year",
    y = "General budget per resident"
  ) +
  theme_bw() +
  theme(
    panel.grid.minor = element_blank(),
    axis.text = element_text(size = 7)
  )

ggsave(
  "output/figures/grid_over_time.png",
  grid_over_time,
  width = 6.0,
  height = 2.8,
  dpi = 300,
  bg = "white"
)


# A Category and a Number: the Benchmark -----------------------------------------------------------

# Budget per resident, for every town that has both numbers
nj_2025 <- nj_2025 |>
  mutate(per_resident = budget_m * 1e6 / pop)

# Why the median and not the mean? Check the extremes first (2.4's impossible-values check).
nj_2025 |>
  filter(!is.na(per_resident)) |>
  summarize(
    towns = n(),
    median = median(per_resident),
    mean = mean(per_resident)
  )

nj_2025 |>
  slice_max(per_resident, n = 3) |>
  select(town, county, pop, budget_m, per_resident)


# Figure 11: One Row per Category, One Bar Each, Sorted ------------------------------------------

# Say: "Start with ufb_mercer, and then add a column for the budget per resident."
ufb_mercer <- ufb_mercer |>
  mutate(per_resident = budget_m * 1e6 / pop)

# Shorter names, so the labels fit. Keep both Hopewells apart!
mercer_bars <- ufb_mercer |>
  mutate(
    town = town |>
      str_replace(" township", " twp") |>
      str_replace(" borough", " boro")
  )

# fct_reorder(town, per_resident) puts the towns in order of the number, so the bars read as a
# ranking. geom_vline() draws the benchmark at a value on the x-axis.
fig11 <- ggplot(
  mercer_bars,
  aes(
    x = per_resident,
    y = fct_reorder(town, per_resident)
  )
) +
  geom_col() +
  geom_vline(xintercept = 1679, linetype = "dashed") +
  annotate("text", x = 1740, y = 1.3, label = "NJ median town: $1,679", hjust = 0, size = 2.8) +
  scale_x_continuous(labels = scales::dollar, expand = expansion(mult = c(0, 0.08))) +
  labs(
    title    = "Ewing budgets less per resident than most Mercer County towns",
    subtitle = "Each bar is one of the 12 Mercer County towns, 2025",
    x        = "General budget per resident",
    y        = NULL,
    caption  = "Source: NJ DCA, User Friendly Budget Database, 2025"
  ) +
  theme(
    plot.title = element_text(size = 10.5),
    plot.subtitle = element_text(size = 8.5),
    plot.caption = element_text(size = 7)
  )

print(fig11)

ggsave(
  "output/figures/fig11_mercer_sorted_bars.png",
  fig11,
  width = 5.8,
  height = 3.2,
  dpi = 300,
  bg = "white"
)


# Figure 12: Many Rows per Category, One Boxplot Each --------------------------------------------

# Map the qualitative variable to x and the quantitative one to y, and geom_boxplot() computes a
# box for every group: the middle half of the towns, with a line at the median. After the $6,000
# filter one village is left (Ridgefield Park; Ridgewood filed no budget and Loch Arbour is over
# $6,000): one town is not a group.
under_6k <- nj_2025 |>
  filter(!is.na(per_resident), per_resident < 6000, type != "village")

nrow(under_6k)

sum(nj_2025$per_resident >= 6000, na.rm = TRUE)

fig12 <- ggplot(
  under_6k,
  aes(
    x = fct_reorder(type, per_resident),
    y = per_resident
  )
) +
  geom_boxplot() +
  scale_y_continuous(labels = scales::dollar) +
  labs(
    title    = "Townships budget the least per resident",
    subtitle = paste0(
      "One box per kind of municipality, 2025: the ", nrow(under_6k), " towns under $6,000\n(",
      sum(nj_2025$per_resident >= 6000, na.rm = TRUE), " towns at $6,000 or more left out, and the one village)"
    ),
    x        = "Kind of municipality",
    y        = "General budget per resident",
    caption  = "Source: NJ DCA, User Friendly Budget Database, 2025"
  ) +
  theme(
    plot.title = element_text(size = 10.5),
    plot.subtitle = element_text(size = 8),
    plot.caption = element_text(size = 7)
  )

print(fig12)

ggsave(
  "output/figures/fig12_boxplot_by_type.png",
  fig12,
  width = 5.0,
  height = 3.1,
  dpi = 300,
  bg = "white"
)

# The medians under the figure
under_6k |>
  group_by(type) |>
  summarize(
    n = n(),
    median = round(median(per_resident))
  )


# Two Categories: the Two-Way Table ----------------------------------------------------------------

# The two-way table of counts behind all three panels of Figure 13. The three villages are left out.
two_way <- nj_2025 |>
  filter(type != "village") |>
  count(type, state_plan)

two_way |>
  pivot_wider(names_from = state_plan, values_from = n)

# Conditional proportions: within each kind of town, the share with each answer
two_way |>
  group_by(type) |>
  mutate(prop = round(n / sum(n), 2)) |>
  pivot_wider(id_cols = type, names_from = state_plan, values_from = prop)

# Mercer only, for the by-hand question
ufb_mercer |>
  count(type, state_plan) |>
  pivot_wider(names_from = state_plan, values_from = n, values_fill = 0)


# Figure 13: Stack, Dodge, Fill ------------------------------------------------------------------

no_village <- nj_2025 |>
  filter(type != "village")

stack <- ggplot(no_village, aes(y = type, fill = state_plan)) +
  geom_bar() +
  scale_fill_grey(start = 0.2, end = 0.85, na.value = "grey95") +
  scale_x_continuous(breaks = c(0, 100, 200)) +
  labs(
    title = "\"stack\" (default)",
    x = "Number of towns",
    y = NULL,
    fill = "State plan?"
  ) +
  theme(
    plot.title = element_text(family = "mono", size = 8),
    legend.position = "none"
  )

dodge <- ggplot(no_village, aes(y = type, fill = state_plan)) +
  geom_bar(position = "dodge") +
  scale_fill_grey(start = 0.2, end = 0.85, na.value = "grey95") +
  labs(
    title = "\"dodge\"",
    x = "Number of towns",
    y = NULL,
    fill = "State plan?"
  ) +
  theme(
    plot.title = element_text(family = "mono", size = 8),
    legend.position = "none"
  )

fill <- ggplot(no_village, aes(y = type, fill = state_plan)) +
  geom_bar(position = "fill") +
  scale_fill_grey(start = 0.2, end = 0.85, na.value = "grey95") +
  scale_x_continuous(breaks = c(0, 0.5, 1)) +
  labs(
    title = "\"fill\"",
    x = "Proportion of towns",
    y = NULL,
    fill = "State plan?"
  ) +
  theme(
    plot.title = element_text(family = "mono", size = 8),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 8)
  )

fig13 <- stack + dodge + fill

print(fig13)

ggsave(
  "output/figures/fig13_stack_dodge_fill.png",
  fig13,
  width = 6.8,
  height = 2.4,
  dpi = 300,
  bg = "white"
)
