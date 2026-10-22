# scripts/05_police_salary.R
# The decision: I just took a full-time job at TCNJ. My partner and I need to pick a town to live in.
# My partner is a police officer and will join that town's department. 
# So, how does pay for full-time officers compare across towns within a 20-minute drive of Ewing?
# Benchmark: the median of those same towns.


# Settings, Packages, and Load the Data ---------------------------------------------------

library(tidyverse)

max_drive_min <- 20   # change to 25 to see the next ring of towns (the drive-time table stops at 25)

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

# Drive times are imported manually. 
# OpenStreetMap's routing service (router.project-osrm.org), queried October 22, 2026. 
# Start: TCNJ (40.2712, -74.7829, from Wikipedia). End: the Census Bureau's
# internal point for each town (TIGERweb, INTPTLAT and INTPTLON). 


# The times assume no traffic

# Every town within about 15 straight-line miles of TCNJ was checked; these are all the towns
# that came back at 25 minutes or less. drive_sec is copied exactly as the service returned it.
# The key is muni_code, not the name: Hamilton, Lawrence, Hopewell, and Mansfield are each
# the name of more than one NJ town!
drive_times <- tribble(
  ~muni_code, ~drive_sec,
  "1102",      219.2,     # Ewing township, Mercer
  "1111",      456.8,     # Trenton city, Mercer
  "1108",      639.7,     # Pennington borough, Mercer
  "1107",      795.3,     # Lawrence township, Mercer
  "1106",     1136.7,     # Hopewell township, Mercer
  "1113",     1145.6,     # West Windsor township, Mercer
  "1105",     1170.6,     # Hopewell borough, Mercer
  "1103",     1185.2,     # Hamilton township, Mercer
  "0303",     1256.2,     # Bordentown city, Burlington
  "1218",     1287.3,     # Plainsboro township, Middlesex
  "0304",     1309.8,     # Bordentown township, Burlington
  "1114",     1327.5,     # Princeton borough, Mercer
  "0314",     1369.6,     # Fieldsboro borough, Burlington
  "1026",     1405.7,     # West Amwell township, Hunterdon
  "1017",     1474.1,     # Lambertville city, Hunterdon
  "0318",     1499.3      # Mansfield township, Burlington
) |>
  mutate(
    drive_min = drive_sec / 60
  )


# Merge Drive Times onto the Budget Data ---------------------------------------------------

# Before the merge, what I expect:
# 1) Rows: drive_times is the left table, so 16 rows in and 16 rows out.
# 2) Drops: none. Every code above was copied from police, so all 16 should find a match.
#    Trenton will match but have NA in every pol_ column (no 2026 budget on file).
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
  anti_join(drive_times, join_by(muni_code))   # expect 548 rows (564 - 16): the towns we didn't route

drive_police <- drive_times |>
  left_join(police, join_by(muni_code))

# Three checks after the merge: expect 16 rows and 15 columns
dim(drive_police)
names(drive_police)
summary(drive_police)


# Curate Dataset -----------------------------------------------------------------------------

# keep the towns within the drive
near <- drive_police |>
  filter(drive_min <= max_drive_min)

dim(near)   # 8 towns within 20 minutes

# Which towns can't give us an average full-time salary, and why?
# - pol_ft is NA: no 2026 budget on file (Trenton)
# - pol_ft is 0: the town reports no officers of its own (Hopewell borough)
# - pol_pt is over 0: base pay is one total for full- AND part-time officers, so dividing it
#   by full-time officers alone would overstate full-time pay. None within 20 minutes; at 25
#   minutes this drops Bordentown city, Bordentown township, and Plainsboro.
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

# Average salary = base pay for all officers / number of full-time officers.
# Base pay is the annual pay rate, before overtime. It is an average across every rank,
# from new officers to the chief, so it is NOT the starting salary my partner would see.
near_salary <- near |>
  filter(!is.na(pol_ft) & pol_ft > 0 & pol_pt == 0) |>
  mutate(
    avg_salary = pol_base_pay / pol_ft
  ) |>
  select(municipality, county, drive_min, pol_ft, pol_base_pay, avg_salary) |>
  arrange(desc(avg_salary))

near_salary   # 6 towns within 20 minutes

# If you change max_drive_min to 25, look hard at Lambertville before trusting it:
# $162,557 in base pay for 11 full-time officers is about $14,800 each. R won't find that
# suspicious. That's our job!


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
      "Average base pay per full-time officer, 2026 budgets.\nTowns within ", max_drive_min,
      " minutes of TCNJ. Dashed line: their median ($", round(benchmark / 1000, 1), " thousand).",
      sep = ""
    ),
    x = "Average base pay per full-time officer (thousands of dollars)",
    y = NULL,
    caption = "Source: NJ DCA, User Friendly Budget Database, 2026 sheet. Drive times: OpenStreetMap (OSRM), no traffic.\nNot shown: Trenton (no 2026 budget on file) and Hopewell borough (no officers of its own)."
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
