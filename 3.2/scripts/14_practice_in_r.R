# scripts/14_practice_in_r.R


#####  I recommend the following strategy when completing this practice

# STEP 1: Attempt each task and answer the questions first without using AI.

# 05 and 06 every two- and three-variable graphic, 07 the key repair, and 09 and 10 every join.

# STEP 3: Ask AI for help identifying specific problems with the script you wrote
# i.e., do not give AI the whole prompt! Instead, give it specifically what you wrote
# with no context and ask it to identify the problem and suggest a solution.

# STEP 4: Look at the practice solutions.


#### HOWEVER HOWEVER HOWEVER
# It's better to use the syntax from practice_solutions to answer the questions
# than to do nothing!


# Every Task Starts With the Three Checks ---------------------------------------------------------

# Before you draw or merge anything, write down what you expect (what one row is, how many rows
# and columns), then run the three checks on every table you use:
#   dim()       how many rows and columns?
#   names()     what are the columns called?
#   summary()   what is in each column, and how many NAs?
# Run them again after every filter() you save and after every merge.


# Packages and Load the Data ---------------------------------------------------------------------

library(tidyverse)

# Source 1: every New Jersey town in the 2025 sheet of the UFB Database, one row per town.
# col_types keeps the town code as text, so every file reads the key the same way.
nj_2025 <- read_csv(
  "data/nj_2025.csv",
  col_types = cols(muni_code = col_character())
)

# Source 1 again, every town in every budget year 2016 to 2025: one row per town-year
nj_all <- read_csv(
  "data/nj_2016_2025.csv",
  col_types = cols(muni_code = col_character())
)

# Source 2: the Division of Taxation's average residential tax bill, 2024, as printed
tax <- read_csv(
  "data/avg_tax_bill_2024.csv",
  col_types = cols(
    county_code = col_character(),
    district_code = col_character()
  )
)

# Source 3: Census QuickFacts for 19 towns near TCNJ, plus Mercer County and New Jersey
quickfacts <- read_csv(
  "data/quickfacts_near_tcnj.csv",
  col_types = cols(fips = col_character())
)


# Task 1. Know Your Key, Then Count --------------------------------------------------------------

# The three checks on nj_2025 first.
# Hints: count(muni_code) |> filter(n > 1); distinct(muni_code) |> dim() to count the different
#        codes; geom_bar() with aes(y = county); count(county) |> mutate(prop = n / sum(n));
#        fct_rev(fct_infreq(county))
# Tip: the county table has 21 rows, so Mercer is not in the first 10. Try arrange(n).




# Task 2. One Number, Two Bin Widths -------------------------------------------------------------

# The three checks on nj_2025 first, and on under_15k once you save it.
# Hints: geom_histogram() with no binwidth first; then filter(density <= 15000) and
#        geom_histogram(binwidth = 500, boundary = 0), then binwidth = 2500




# Task 3. Two Variables: Ewing Over Time, Against the State --------------------------------------

# The three checks on nj_all first, and on every table you save (nj_pr, ewing, state_by_year,
# ufb_mercer).
# Hints: mutate(per_resident = budget / pop) saved as nj_pr; filter(town == "Ewing township");
#        group_by(year) |> summarize(towns = n(), median_per_resident = median(per_resident));
#        a second geom_line(data = ..., aes(x = year, y = ...), linetype = "dashed");
#        filter(nj_2025, county == "Mercer") saved as ufb_mercer;
#        for the scatterplot: geom_point() + geom_smooth(method = "lm", se = FALSE)
# Tip: arrange(desc(per_resident)) puts the largest at the top, the same rows slice_max() keeps.
# Tip: the points have no names. To tell which is Ewing, print ufb_mercer |>
#      select(town, pop, budget_m) and match the numbers to the plot.




# Task 4. Three or More Variables ----------------------------------------------------------------

# The three checks on every table you start from.
# Hints: aes(colour = type) inside vs colour = "steelblue" outside; facet_wrap(~ town, scales = "free_y");
#        geom_bar(position = "fill") with aes(y = type, fill = state_plan)
# Tip: the workbook draws the facets from mercer_years but never makes it. It is nj_pr |>
#      filter(county == "Mercer") |> select(town, year, per_resident): 120 rows.
# Tip: the villages are type == "village" (lower case). Leave them out with filter(type != ...).
# Tip: the share answering Yes for each type: group_by(type) |> summarize(towns = n(),
#      yes = sum(state_plan == "Yes", na.rm = TRUE)), then divide.




# Task 5. Fix the Key, Then Merge ----------------------------------------------------------------

# The three checks on both tables before the merge, and on the merged table after it.
# Hints: str_to_lower(), str_squish(), str_replace(" township$", " twp"), str_replace(" borough$", " boro");
#        anti_join(x, y, by = "key") both ways; a tribble() of fixes and coalesce(); left_join(); dim()
# Tip: the codes are text, so filter(county_code == "11"), with quotation marks.
# Tip: on the raw names, town and district have different column names. rename(town = district)
#      first (new = old), then anti_join(..., by = "town").




# Task 6. The Rate, Labeled and Saved ------------------------------------------------------------

# The three checks on quickfacts, on data/nj_merged.csv once you read it, and on the merged table.
# Hints: filter() out the county and state rows (geography != "..." & geography != "...");
#        str_remove(", New Jersey$"), then str_remove(", Mercer County$") and the same for the
#        other counties, to cut each name down to the town;
#        case_when(place %in% c(...) ~ "Burlington", ..., .default = "Mercer") for the county;
#        read_csv("data/nj_merged.csv"); left_join(..., by = c("county", "key"));
#        mutate(tax_share = avg_tax_bill / median_hh_income * 100); geom_vline(xintercept = 9.6);
#        labs(); ggsave("output/ewing_vs_neighbors.png", width = 6, height = 4)
# Tip: nj_merged.csv already has county and key, built with the Task 5 rules. Spell the counties
#      the same way ("Burlington", not "Burlington County"), and use your Task 5 fixes on the
#      QuickFacts key too: Princeton's key is "princeton boro".
# Tip: for Ewing in its own color, make a column with if_else(town == "Ewing township", "Ewing",
#      "Other towns") and map fill to it inside aes().
# Tip: at width = 6, long titles run off the edge. Open the saved PNG and check.
