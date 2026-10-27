# scripts/04_one_variable.R
# Workbook 3.2, Section 2, "One Variable": Figure 2 (the type of the variable picks the graphic),
# count() as the frequency table, Figure 3 (geom_col() on the plans table, counts and proportions),
# Figure 4 (alphabetical order vs sorted by count), Figure 5 (pie vs bar), Figure 6 (the 12 Mercer
# land areas at two bin widths), Figure 7 (R's 30 bins vs bins you chose), and the blank grids.


# Packages and Load the Data ---------------------------------------------------------------------

library(tidyverse)
library(patchwork)   # puts two plots side by side: a + b

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


# Figure 2: A Category Gets a Bar Chart; a Number Gets a Histogram -------------------------------

# A: state_plan is qualitative, so geom_bar() counts the rows in each category.
a <- ggplot(nj_2025, aes(x = state_plan)) +
  geom_bar() +
  labs(
    title = "A. A category: geom_bar()",
    x = "On the state health plan?",
    y = "Number of towns"
  ) +
  theme(plot.title = element_text(size = 9))

# B: pct_collected (the share of 2024 property taxes each town actually collected) is quantitative,
# so geom_histogram() sorts the rows into bins and counts each bin. Towns that reported nothing, or
# an impossible number (over 100 percent), or under 90 are left out, and the caption says so.
collected <- nj_2025 |>
  filter(!is.na(pct_collected), pct_collected >= 90, pct_collected <= 100)

nrow(collected)                                     # towns drawn

sum(is.na(nj_2025$pct_collected))                   # reported nothing

sum(nj_2025$pct_collected > 100, na.rm = TRUE)      # reported more than 100 percent

sum(nj_2025$pct_collected < 90, na.rm = TRUE)       # reported less than 90 percent

b <- ggplot(collected, aes(x = pct_collected)) +
  geom_histogram(binwidth = 0.5, boundary = 90) +
  labs(
    title = "B. A number: geom_histogram()",
    x = "Percent of 2024 taxes collected",
    y = "Number of towns"
  ) +
  theme(plot.title = element_text(size = 9))

fig02 <- a + b

print(fig02)

ggsave(
  "output/figures/fig02_bar_or_histogram.png",
  fig02,
  width = 6.0,
  height = 2.5,
  dpi = 300,
  bg = "white"
)


# The Frequency Table, by count() ----------------------------------------------------------------

# Say: "Start with nj_2025, and then count the rows in each answer, and then add a column that
# divides each count by the sum of the counts."
plans <- nj_2025 |>
  count(state_plan) |>
  mutate(prop = n / sum(n))

plans

# Count before you draw: the same credit rating typed many ways
nj_2025 |>
  count(sp_rating, sort = TRUE) |>
  print(n = 14)

# The 13 college towns from 3.1, and their state_plan answers (for the counting practice)
college_towns <- c(
  "Camden city", "Ewing township", "Galloway township", "Glassboro borough",
  "Hoboken city", "Madison borough", "Mahwah township", "Montclair township",
  "New Brunswick city", "Princeton borough", "South Orange Village township",
  "Union township", "West Long Branch borough"
)

nj_2025 |>
  filter(town %in% college_towns, county != "Hunterdon") |>     # there is a second Union township in Hunterdon
  select(town, county, state_plan) |>
  arrange(town)


# Figure 3: geom_col() on the plans Table: Counts, Then Proportions ------------------------------

f3a <- ggplot(plans, aes(x = state_plan, y = n)) +
  geom_col() +
  labs(
    title = "geom_col(): y = n",
    x = "On the state health plan?",
    y = "Number of towns"
  ) +
  theme(plot.title = element_text(family = "mono", size = 9))

f3b <- ggplot(plans, aes(x = state_plan, y = prop)) +
  geom_col() +
  labs(
    title = "geom_col(): y = prop",
    x = "On the state health plan?",
    y = "Proportion of towns"
  ) +
  theme(plot.title = element_text(family = "mono", size = 9))

fig03 <- f3a + f3b

print(fig03)

ggsave(
  "output/figures/fig03_col_counts_props.png",
  fig03,
  width = 6.0,
  height = 2.6,
  dpi = 300,
  bg = "white"
)


# Figure 4: The Order of the Bars ----------------------------------------------------------------

# fct_infreq() orders a qualitative variable by how often each value appears, most common first.
# On a y-axis "first" is the bottom, so fct_rev() turns it over and the biggest bar lands on top.
f4a <- ggplot(nj_2025, aes(y = county)) +
  geom_bar() +
  labs(
    title = "alphabetical (R's default)",
    x = "Number of towns",
    y = NULL
  ) +
  theme(
    plot.title = element_text(size = 9),
    axis.text.y = element_text(size = 7)
  )

f4b <- ggplot(nj_2025, aes(y = fct_rev(fct_infreq(county)))) +
  geom_bar() +
  labs(
    title = "fct_rev(fct_infreq(county))",
    x = "Number of towns",
    y = NULL
  ) +
  theme(
    plot.title = element_text(family = "mono", size = 9),
    axis.text.y = element_text(size = 7)
  )

fig04 <- f4a + f4b

print(fig04)

ggsave(
  "output/figures/fig04_bar_order.png",
  fig04,
  width = 6.0,
  height = 3.2,
  dpi = 300,
  bg = "white"
)


# The Blank Grid for the Counting Practice (Drawing a Bar Chart by Hand) ---------------------

grid_bars <- ggplot() +
  scale_x_discrete(limits = c("No", "Yes", "NA")) +
  scale_y_continuous(breaks = 0:7, limits = c(0, 7), expand = c(0, 0)) +
  labs(
    x = "state_plan",
    y = "Number of towns"
  ) +
  theme_bw() +
  theme(panel.grid.minor = element_blank())

ggsave(
  "output/figures/grid_bars.png",
  grid_bars,
  width = 3.2,
  height = 2.0,
  dpi = 300,
  bg = "white"
)


# Figure 5: Why Not a Pie? -----------------------------------------------------------------------

# ggplot2 has no geom_pie(): a pie is a stacked bar bent into a circle with coord_polar(), and the
# authors made it awkward on purpose. You do not need to learn this code.
kinds <- nj_2025 |>
  count(type) |>
  mutate(type = fct_reorder(type, n))

kinds

pie <- ggplot(kinds, aes(x = "", y = n, fill = type)) +
  geom_col(width = 1, colour = "white") +
  coord_polar(theta = "y") +
  scale_fill_grey(start = 0.25, end = 0.9) +
  labs(
    title = "A. Pie chart",
    x = NULL,
    y = NULL,
    fill = "Kind"
  ) +
  theme_void() +
  theme(
    plot.title = element_text(size = 9, hjust = 0.5),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 8)
  )

bars <- ggplot(kinds, aes(x = n, y = type)) +
  geom_col() +
  labs(
    title = "B. Bar chart",
    x = "Number of towns",
    y = NULL
  ) +
  theme(plot.title = element_text(size = 9))

fig05 <- pie + bars

print(fig05)

ggsave(
  "output/figures/fig05_pie_vs_bar.png",
  fig05,
  width = 6.0,
  height = 2.5,
  dpi = 300,
  bg = "white"
)


# Figure 6: Two Bin Widths, Same 12 Towns --------------------------------------------------------

# By hand first: sort the 12 land areas
sort(ufb_mercer$land_sqmi)

# binwidth is the width of each bin; boundary = 0 makes the bins start at 0, 10, 20, ... (without
# it R centers a bin on zero, which matches no table you would make by hand).
w10 <- ggplot(ufb_mercer, aes(x = land_sqmi)) +
  geom_histogram(binwidth = 10, boundary = 0, colour = "white") +
  scale_x_continuous(breaks = seq(0, 60, 10)) +
  scale_y_continuous(breaks = 0:7) +
  labs(
    title = "binwidth = 10",
    x = "Land area (square miles)",
    y = "Number of towns"
  ) +
  theme(plot.title = element_text(family = "mono", size = 9))

w20 <- ggplot(ufb_mercer, aes(x = land_sqmi)) +
  geom_histogram(binwidth = 20, boundary = 0, colour = "white") +
  scale_x_continuous(breaks = seq(0, 60, 20)) +
  scale_y_continuous(breaks = 0:7) +
  labs(
    title = "binwidth = 20",
    x = "Land area (square miles)",
    y = NULL
  ) +
  theme(plot.title = element_text(family = "mono", size = 9))

fig06 <- w10 + w20

print(fig06)

ggsave(
  "output/figures/fig06_two_widths.png",
  fig06,
  width = 5.6,
  height = 2.4,
  dpi = 300,
  bg = "white"
)


# Figure 7: What R Does If You Do Not Choose -----------------------------------------------------

# density is residents per square mile. No binwidth: R uses 30 bins and prints a message.
f7a <- ggplot(nj_2025, aes(x = density)) +
  geom_histogram() +
  labs(
    title = "A. geom_histogram(), R's 30 bins",
    x = "Residents per square mile",
    y = "Number of towns"
  ) +
  theme(plot.title = element_text(size = 9))
# `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.

# Towns that are packed tighter than anywhere else stretch the axis. Keep the towns under 15,000
# per square mile and SAY SO in the title.
under_15k <- nj_2025 |>
  filter(density <= 15000)

nrow(nj_2025) - nrow(under_15k)                    # towns left out

f7b <- ggplot(under_15k, aes(x = density)) +
  geom_histogram(binwidth = 500, boundary = 0) +   # bins at 0, 500, 1,000
  labs(
    title = paste0("B. bins of 500; ", nrow(nj_2025) - nrow(under_15k), " towns left out"),
    x = "Residents per square mile",
    y = "Number of towns"
  ) +
  theme(plot.title = element_text(size = 9))

fig07 <- f7a + f7b

print(fig07)

ggsave(
  "output/figures/fig07_default_vs_chosen.png",
  fig07,
  width = 6.0,
  height = 2.5,
  dpi = 300,
  bg = "white"
)

# The table behind panel B, the way you would make it by hand: which bin, how many towns
under_15k |>
  mutate(bin = floor(density / 500) * 500) |>
  count(bin) |>
  print(n = 12)

# The towns off the chart
nj_2025 |>
  slice_max(density, n = 4) |>
  select(town, county, pop, land_sqmi, density)


# The Blank Grid for the Binning Practice --------------------------------------------------------

grid_hist <- ggplot() +
  scale_x_continuous(
    breaks = seq(0, 13000, 1000),
    limits = c(0, 13000),
    expand = c(0, 0),
    labels = function(x) format(x, big.mark = ",")
  ) +
  scale_y_continuous(breaks = 0:6, limits = c(0, 6), expand = c(0, 0)) +
  labs(
    x = "Residents per square mile (bins of 1,000)",
    y = "Number of towns"
  ) +
  theme_bw() +
  theme(
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(size = 6),
    plot.margin = margin(5.5, 16, 5.5, 5.5)     # room for the last tick label
  )

ggsave(
  "output/figures/grid_histogram.png",
  grid_hist,
  width = 6.2,
  height = 2.4,
  dpi = 300,
  bg = "white"
)
