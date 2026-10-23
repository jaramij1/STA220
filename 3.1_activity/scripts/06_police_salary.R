# scripts/06_police_salary.R
# The decision: I just took a full-time job at TCNJ. My partner and I need to pick a town to live in.
# My partner is a police officer and will join that town's department. 
# So, how does pay for full-time officers compare across towns within a 20-minute drive of Ewing?
# Benchmark: the median of those same towns.


# Settings, Packages, and Load the Data ---------------------------------------------------

library(tidyverse)

# Set max drive time (Try changing this value!)
max_drive_min <- 20 

# load data as object
police <- read_csv(
  "data/ufb_2026_police.csv",
  col_types = cols(muni_code = col_character()) # ensure muni_code stays a character
)

# One row is one NJ municipality's 2026 budget. Expect 564 rows and 13 columns.
dim(police)
names(police)
summary(police)  


# Drive Times -------------------------------------------------------------------------------

# Drive times from TCNJ to each police headquarters, made by 05_drive_times.R.
# OpenStreetMap's routing service (router.project-osrm.org), queried October 22, 2026.
# Start: TCNJ (40.2712, -74.7829, from Wikipedia). 
# End: each town's police headquarters (addresses and sources in data/police_hq_addresses.xlsx).

# The times assume no traffic

# 19 departments: all of Mercer County plus the nearby departments in Middlesex, Burlington,
# Hunterdon, and Monmouth (determined by rough approximation on Google Maps)
# Every police HQ within 30 minutes should be here
# Towns with no officers of their own (like Hopewell borough) have no row. 
drive_times <- read_csv(
  "data/police_hq_drive_times.csv",
  col_types = cols(muni_code = col_character())
)

dim(drive_times)   # expect 19 rows and 11 columns

# Keep only the key and the drive time.
drive_times <- drive_times |>
  select(muni_code, department, drive_min)


# Merge Drive Times onto the Budget Data ---------------------------------------------------

# Before the merge, what I expect:
# 1) Rows: drive_times is the left table, so 19 rows in and 19 rows out.
# 2) Drops: none. Every code in drive_times came from the budget data, so all 19 should match.
#    Trenton and South Brunswick will match but have NA in every pol_ column (no 2026 budget).
# 3) Why: the left table decides the rows, and muni_code is a key in both tables.

# Is muni_code really a key? Both of these should return zero rows.
drive_times |>
  count(muni_code) |>
  filter(n > 1)

police |>
  count(muni_code) |>
  filter(n > 1)

# anti_join() both ways
drive_times |>
  anti_join(police, join_by(muni_code))   # expect 0 rows: every nearby town is in the budget data

police |>
  anti_join(drive_times, join_by(muni_code))   # expect 545 rows (564 - 19): the towns we didn't route

drive_police <- drive_times |>
  left_join(police, join_by(muni_code))

# Three checks after the merge: expect 19 rows and 15 columns
dim(drive_police)
names(drive_police)
summary(drive_police)


# Curate Dataset -----------------------------------------------------------------------------

# keep the towns within the drive
near <- drive_police |>
  filter(drive_min <= max_drive_min)

dim(near)   # 7 towns within 20 minutes 

# Which towns can't give us an average full-time salary, and why?
# - pol_ft is NA: no 2026 budget on file (Trenton)
# - pol_ft is 0: the town reports no full-time officers (none here, since towns without a
#   department have no HQ to drive to)
# - pol_pt is over 0: base pay is one total for full- AND part-time officers, so dividing it
#   by full-time officers alone would overstate full-time pay. 
#   This doesn't happen at 20 minutes (Which is why I chose 20 minutes)
#   If you increase to 30 minutes (first draft) this drops Bordentown township and Plainsboro.
near |>
  filter(is.na(pol_ft) | pol_ft == 0 | pol_pt > 0) |>
  select(municipality, no_ufb, pol_ft, pol_pt)

# Always report what you dropped!
near |>
  summarize(
    towns_in_range = n(),
    n_used = sum(!is.na(pol_ft) & pol_ft > 0 & pol_pt == 0),
    n_dropped = sum(is.na(pol_ft) | pol_ft == 0 | pol_pt > 0)
  )

# In an executive summary:
#       The search identified 7 towns within a 20-minute drive of TCNJ. 
#       One town (Trenton) has no 2026 budget on file, so we can't 
#       calculate an average salary for its officers.

# Average salary = base pay for all officers / number of full-time officers.
# Base pay is the annual pay rate, before overtime! It is an average across every rank,
# from new officers to the chief (if that town has one), 
# so it is NOT the starting salary my partner would see.
near_salary <- near |>
  filter(!is.na(pol_ft) & pol_ft > 0 & pol_pt == 0) |>
  mutate(
    avg_salary = pol_base_pay / pol_ft
  ) |>
  select(municipality, county, drive_min, pol_ft, pol_base_pay, avg_salary) |>
  arrange(desc(avg_salary))

near_salary   # 6 towns within 20 minutes

# At 25 minutes, Princeton ($117,227) and Robbinsville ($115,429) join. 

# Don't fundamentally trust the data!
# Lambertville lists $162,557 in base pay for 
# 11 full-time officers is about $14,800 each. 
# R won't find that suspicious. That's our job!


# Benchmark --------------------------------------------------------------------------------
# The MEDIAN of the towns we could actually live in

benchmark <- median(near_salary$avg_salary)
benchmark   # about $113,874 for the 6 towns within 20 minutes

# How far each town is above (+) or below (-) the benchmark
near_salary |>
  mutate(
    diff_from_median = avg_salary - benchmark
  ) |>
  select(municipality, avg_salary, diff_from_median)


# Create Figure, with Benchmark --------------------------------------------------------------
# ggplot2 starts in Module 3. fct_reorder() (from 02_cards.R) sorts the bars by salary, and
# geom_vline() draws the benchmark as a dashed line, like the dashed line in 03_ewing.R.

# Dividing by 1,000 keeps the axis readable (otherwise R prints 1e+05)
salary_fig <- ggplot(
  near_salary,
  aes(
    x = avg_salary / 1000,
    y = fct_reorder(municipality, avg_salary)
  )
) +
  geom_col() +
  geom_vline(
    xintercept = benchmark / 1000,
    linetype = "dashed"
  ) +
  labs(
    # the finding for the 20-minute towns; rewrite it if you change max_drive_min!
    title = "West Windsor, Hamilton, and Ewing pay officers\nabout $20,000 more than the other nearby towns",
    subtitle = paste(
      "Average base pay per full-time officer, 2026 budgets.\nTowns whose police HQ is within ", max_drive_min,
      " minutes of TCNJ. Dashed line: their median ($", round(benchmark / 1000, 1), " thousand).",
      sep = ""
    ),
    x = "Average base pay per full-time officer (thousands of dollars)",
    y = "Town",
    caption = "Source: NJ DCA, User Friendly Budget Database, 2026 sheet. Drive times: OpenStreetMap (OSRM), no traffic.\nNot shown: Trenton (no 2026 budget on file). Hopewell borough has no department; Hopewell Township's officers cover it."
  )

salary_fig

ggsave(
  "output/figures/police_salary_near_ewing.png",
  salary_fig,
  width = 8,
  height = 4.5,
  dpi = 300,
  bg = "white"
)
