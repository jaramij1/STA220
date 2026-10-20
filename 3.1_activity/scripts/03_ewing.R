# scripts/03_your_town.R
# Example Part B. 


# Settings, Packages, and Load the Data ---------------------------------------------------

library(tidyverse)
nj  <- read_csv("data/ufb_activity_2016_2025.csv")   
cpi <- read_csv("data/cpi_u_2016_2025.csv")

my_town   <- "Ewing township"   # CASE SENSITIVE!
my_county <- "Mercer"           # CASE SENSITIVE!

# Get CPI for 2025 and merge into full dataset of all towns (once, up here, so every block below can use it)
cpi_2025 <- cpi$cpi_u[cpi$year == 2025]
nj <- nj |>
  left_join(cpi, by = "year") |>
  mutate(to_2025 = cpi_2025 / cpi_u)    # multiply an amount from year y by this to get 2025 dollars

# Curate dataset ---------------------------------------------------------------------------------

# limit to ufb for your town
town <- nj |>
  filter(municipality == my_town, county == my_county)

# check that you have observations for your town
nrow(town) > 0

# limit columns
town <- town |>
  select(year, pop, budget, local_tax, state_aid, surplus, rev_total, police_ft, net_debt_pc, to_2025)

# One row is for one budget-year!



# Benchmark --------------------------------------------------------------
# The MEDIAN! NJ municipality

# Limit to towns with a budget and a population
nj_latest <- nj |>
  filter(year == 2025, !is.na(budget), budget > 0, !is.na(pop), pop > 0)

#NOTE: Could be future missing depending on what variables are used!!!


# Calculating rates
nj_latest |>
  summarize(towns               = n(),
            budget_per_resident = median(budget / pop))                     # about $1,679 (550 towns)

nj_latest |>
  filter(!is.na(police_ft), police_ft > 0) |>                               # only towns with their own force
  summarize(towns               = n(),
            officers_per_1000   = median(police_ft / pop * 1000))           # about 2.4 (413 towns)

nj_latest |>
  filter(!is.na(state_aid)) |>
  summarize(towns               = n(),
            state_aid_per_res   = median(state_aid / pop))                  # about $95 (550 towns)

nj_latest |>
  filter(!is.na(surplus), rev_total > 0) |>
  summarize(towns               = n(),
            surplus_pct         = median(surplus / rev_total * 100))        # about 12 percent (549 towns)




# Compare 2025 to benchmark -----------------------------------
# most recent year
latest <- town |>
  filter(!is.na(budget)) |>
  slice_max(year, n = 1)

# Create variables for comparison in most recent year; not all of these are used in figure
latest |>
  transmute(year,
            budget_per_resident = budget / pop,              # median NJ municipality: about $1,679
            officers_per_1000   = police_ft / pop * 1000,    # median: about 2.4
            state_aid_per_res   = state_aid / pop,           # median: about $95
            surplus_pct         = surplus / rev_total * 100) # median: about 12 percent

# Convert to real dollars -------------------------------------------------

town |>
  filter(year %in% c(2016, 2025)) |>
  transmute(year,
            levy          = local_tax,
            levy_2025_usd = local_tax * to_2025,
            levy_pr_real  = local_tax * to_2025 / pop) |>
  pivot_longer(-year) |>
  pivot_wider(names_from = year, values_from = value, names_prefix = "y") |>
  mutate(change_pct = (y2025 - y2016) / y2016 * 100)


# Median NJ municipality each year: levy per resident, in 2025 dollars
typical <- nj |>
  filter(!is.na(local_tax), local_tax > 0, !is.na(pop), pop > 0) |>
  group_by(year) |>
  summarize(towns                = n(),
            levy_pr_2025_dollars = median(local_tax * to_2025 / pop))

typical   # one row per budget year for median NJ town


# Create figure, with benchmark ---------------------------------------
ggplot(town, aes(x = year, y = local_tax * to_2025 / pop)) +
  geom_col() +
  geom_line(data = typical, aes(x = year, y = levy_pr_2025_dollars), linetype = "dashed") +
  scale_x_continuous(breaks = 2016:2025) +
  labs(title = paste(my_town, "municipal tax levy per resident, in 2025 dollars"),   # replace with the finding once you see it!
       subtitle = "Each bar is one budget year. Dashed line: the median New Jersey municipality that year.",
       x = NULL, y = "Dollars per resident (2025 dollars)",
       caption = "Source: NJ DCA, User Friendly Budget Database, 2016 to 2025; BLS CPI-U")