# scripts/01_part_a.R
# Activity 3.2a, Part A: Run, then read.
#
# Eleven blocks, A1 to A11. Each block draws one kind of graphic from workbook 3.2 with real data
# you have not seen drawn this way. Before you run a block, write your prediction on the handout.
# Then run the block (highlight it, Ctrl+Enter / Cmd+Enter), look at the Plots pane and the
# console, and answer the handout's questions for that block. 
#
# Every command here is one you have seen in Module 2, 3.1, or 3.2. The data are the four
# sources from workbook 3.2, already merged by the 3.2 scripts (see README.md):
#   nj          every NJ town in 2025 with its 2024 tax bill (Sources 1 and 2): one row per town
#   nj_all      every town in every budget year, 2016 to 2025 (Source 1): one row per town-year
#   near        the 19 towns near TCNJ (Sources 1, 2, and 3): one row per town
#   bills       the 12 Mercer towns' tax bills, 2016 to 2024 (Source 2): one row per town-year
#   benchmarks  the Mercer County and NJ average bills, 2016 to 2024 (Source 2): one row per year


# Settings, Packages, and Load the Data ---------------------------------------------------

library(tidyverse)

nj         <- read_csv("data/nj_merged.csv",                  col_types = cols(muni_code = "c"))
nj_all     <- read_csv("data/nj_2016_2025.csv",               col_types = cols(muni_code = "c"))
near       <- read_csv("data/near_tcnj.csv",                  col_types = cols(muni_code = "c", fips = "c"))
bills      <- read_csv("data/mercer_tax_bill_2016_2024.csv",  col_types = cols(county_code = "c", district_code = "c"))
benchmarks <- read_csv("data/tax_bill_benchmarks_2016_2024.csv", show_col_types = FALSE)

# the three checks, on the table most blocks use
dim(nj)
names(nj)
summary(nj)

# the key check (Module 2.3): you want zero rows
nj |>
  count(muni_code) |>
  filter(n > 1)

# the five counties around TCNJ, used in several blocks
five <- nj |>
  filter(county %in% c("Mercer", "Burlington", "Middlesex", "Somerset", "Hunterdon"))

dim(five)                 # how many towns? write it down before A1


# A1. One category: geom_bar() counts rows -----------------------------------------------
# Say: "Start with five, map the kind of municipality to y, and count the rows into one bar each."

five |>
  count(type)             # the frequency table, so you can check the bars

ggplot(five, aes(y = type)) +
  geom_bar()


# A2. The same table, drawn from numbers already in it: geom_col() ------------------------
# count() makes the table; mutate() adds the proportion; geom_col() draws the proportion column.

kinds <- five |>
  count(type) |>
  mutate(prop = n / sum(n))

kinds

ggplot(kinds, aes(x = prop, y = fct_reorder(type, prop))) +
  geom_col() +
  labs(x = "Proportion of the 124 towns", y = NULL)


# A3. One number: geom_histogram() bins it -------------------------------------------------
# debt_per_resident is each town's net debt divided by its population, in dollars (UFB, 2025).
# Towns over $6,000 would stretch the axis; they are filtered out, and the title must say so.

under_6k <- nj |>
  filter(!is.na(debt_per_resident), debt_per_resident <= 6000)

nrow(nj) - nrow(under_6k)           # towns left out (NA, or over $6,000)

ggplot(under_6k, aes(x = debt_per_resident)) +
  geom_histogram(binwidth = 250, boundary = 0) +
  labs(x = "Net debt per resident, 2025 (bins of $250)", y = "Number of towns")

ggplot(under_6k, aes(x = debt_per_resident)) +
  geom_histogram(binwidth = 1000, boundary = 0) +
  labs(x = "Net debt per resident, 2025 (bins of $1,000)", y = "Number of towns")

# the table behind the second histogram, the way you would make it by hand
under_6k |>
  mutate(bin = floor(debt_per_resident / 1000) * 1000) |>
  count(bin)


# A4. A category and a number, many rows per category: geom_boxplot() ---------------------
# cost_share is the percent of health-plan costs the town's employees pay themselves (UFB, 2025).
# Does it differ between towns on the state plan and towns that are not?

shares <- nj |>
  filter(!is.na(cost_share), !is.na(state_plan), cost_share > 0)

shares |>
  count(state_plan)

ggplot(shares, aes(x = state_plan, y = cost_share)) +
  geom_boxplot() +
  labs(x = "On the state health plan?", y = "Employee share of health costs (percent)")

# what R computed for each box (the median), and how many towns are behind it
shares |>
  group_by(state_plan) |>
  summarize(towns  = n(),
            median = median(cost_share))


# A5. Two numbers: geom_point(), and the line R fits -------------------------------------
# For the 19 towns near TCNJ: does a pricier home mean a bigger tax bill?
# The line is fit once and saved, so the slope below comes from one object.

ggplot(near, aes(x = median_home_value, y = avg_tax_bill)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "Median home value, 2020 to 2024 (dollars)",
       y = "Average residential tax bill, 2024 (dollars)")

value_line <- lm(avg_tax_bill ~ I(median_home_value / 1000), data = near)
value_line                          # the intercept and the slope, per $1,000 of home value

# four towns to check by hand
near |>
  filter(town %in% c("Ewing township", "Trenton city", "Princeton borough", "Hopewell township")) |>
  select(town, median_home_value, avg_tax_bill)


# A6. A number over time, with a benchmark from a second table: geom_line() ---------------
# Hamilton's average tax bill, 2016 to 2024, against the Mercer County average (a second table,
# so the second geom_line() brings its own data and its own aes()).

hamilton <- bills |>
  filter(district == "HAMILTON TWP")

hamilton |>
  filter(tax_year %in% c(2016, 2024))

benchmarks |>
  filter(tax_year %in% c(2016, 2024))

ggplot(hamilton, aes(x = tax_year, y = avg_tax_bill)) +
  geom_line() +
  geom_point() +
  geom_line(data = benchmarks, aes(x = tax_year, y = mercer_county_avg), linetype = "dashed") +
  scale_x_continuous(breaks = 2016:2024) +
  labs(x = "Tax year", y = "Average residential tax bill (dollars)")


# A7. Two categories: stack, dodge, fill ----------------------------------------------------
# county by state_plan for the five counties, towns that answered the question

answered <- five |>
  filter(!is.na(state_plan))

answered |>
  count(county, state_plan)

ggplot(answered, aes(y = county, fill = state_plan)) +
  geom_bar() +
  labs(x = "Number of towns", y = NULL, fill = "State plan?")

ggplot(answered, aes(y = county, fill = state_plan)) +
  geom_bar(position = "fill") +
  labs(x = "Proportion of towns", y = NULL, fill = "State plan?")


# A8. A third variable as color: inside aes() or outside? And the mistake. ----------------

ggplot(near, aes(x = mean_commute_min, y = median_rent, colour = county)) +
  geom_point(size = 2)

ggplot(near, aes(x = mean_commute_min, y = median_rent)) +
  geom_point(size = 2, colour = "darkgreen")

ggplot(near, aes(x = mean_commute_min, y = median_rent, colour = "darkgreen")) +
  geom_point(size = 2)


# A9. Small multiples: facet_wrap(), fixed and free scales --------------------------------
# One panel per Mercer town, the tax bill over nine years

ggplot(bills, aes(x = tax_year, y = avg_tax_bill)) +
  geom_line() +
  facet_wrap(~ district) +
  scale_x_continuous(breaks = c(2016, 2020, 2024))

ggplot(bills, aes(x = tax_year, y = avg_tax_bill)) +
  geom_line() +
  facet_wrap(~ district, scales = "free_y") +
  scale_x_continuous(breaks = c(2016, 2020, 2024))


# A10. A heatmap: geom_tile() colors a two-way table ------------------------------------------
# One tile per town and year; the shade is the bill. The table behind it is bills itself:
# one row per town-year, which is exactly what geom_tile() needs.

bills |>
  count(district, tax_year) |>
  filter(n > 1)                     # the key check: 0 rows

range(bills$avg_tax_bill)           # the two ends of the color scale

ggplot(bills, aes(x = tax_year, y = fct_rev(district), fill = avg_tax_bill)) +
  geom_tile(colour = "white") +
  scale_fill_gradient(low = "grey92", high = "grey15") +
  scale_x_continuous(breaks = 2016:2024) +
  labs(x = "Tax year", y = NULL, fill = "Average bill")


# A11 geom_density() --------------------
# A density curve is a histogram with the bins smoothed away. The height is NOT a count: the
# curve is scaled so the total area under it is 1, so you read it for shape, not for numbers.

ggplot(under_6k, aes(x = debt_per_resident)) +
  geom_density() +
  labs(x = "Net debt per resident, 2025 (dollars)", y = "Density")
