# STA 220, Activity 3.2a: Run, Then Read

The R behind Activity 3.2a: eleven blocks of plotting code, one per kind of graphic in workbook 3.2,
on the workbook's real data. Students run each block, predict and read the picture, and answer on the
handout. Part B of the handout (reading ten data sources' documentation) has no code.
Data for Everyday Life, The College of New Jersey, fall 2026.

## For students

Clone the class repository if you have not (clone, not fork), or **Fetch origin** and **Pull origin**
in GitHub Desktop so this folder appears next to 3.1 and 3.2. Open `sta220-activity_3.2a.Rproj`, then
`scripts/01_part_a.R`. Run the first section (it reads the five tables and runs the three checks),
then one block at a time, A1 to A11. Write your prediction on the handout before you run a block.
The only package is the tidyverse.

## What is here

```
3.2a_activity/
  sta220-activity_3.2a.Rproj        # double-click to open the project
  README.md                         # this file
  data/                             # the five tables, copied from 3.2/data/ (see below)
    nj_merged.csv                   # every NJ town, budget year 2025, with its 2024 tax bill
    nj_2016_2025.csv                # every NJ town in every budget year, 2016 to 2025
    near_tcnj.csv                   # the 19 towns within about 30 minutes of TCNJ
    mercer_tax_bill_2016_2024.csv   # the 12 Mercer towns' average tax bills, 2016 to 2024
    tax_bill_benchmarks_2016_2024.csv  # the Mercer County and NJ average bills, 2016 to 2024
    nj_2025.csv                     # every NJ town, budget year 2025 (not used by the script)
  scripts/
    01_part_a.R                     # blocks A1 to A11
  output/                           # empty; nothing is saved by the script
```

## Where did the data come from?

Every file in `data/` is a byte-for-byte copy of the same file in the 3.2 project's `data/` folder,
where the 3.2 README documents each source, its download link, download date, and checksum. In short:

| file | one row is | made by | sources |
|---|---|---|---|
| `nj_2025.csv`, `nj_2016_2025.csv` | a town (2025); a town in a budget year | `3.2/scripts/02_import.R` | Source 1, the NJ DCA User Friendly Budget Database |
| `mercer_tax_bill_2016_2024.csv`, `tax_bill_benchmarks_2016_2024.csv` | a Mercer town in a tax year; a tax year | `3.2/scripts/02_import.R` | Source 2, the NJ Division of Taxation's Average Residential Tax Bill reports, 2016 to 2024 |
| `nj_merged.csv` | a town, with its 2024 bill | `3.2/scripts/09_the_merge.R` | Sources 1 and 2, joined on county and the repaired name |
| `near_tcnj.csv` | one of the 19 towns near TCNJ | `3.2/scripts/10_rates_from_two_sources.R` | Sources 1, 2, and 3 (Census QuickFacts, ACS 2020 to 2024) |

Columns the script uses: `type`, `county`, `state_plan`, `cost_share`, and `debt_per_resident` from
Source 1 (`state_plan` is whether the town's employees are on the State Health Benefits Program;
`cost_share` is the percent of health costs employees pay; `debt_per_resident` is net debt per
capita); `avg_tax_bill` from Source 2; `median_home_value`, `median_rent`, and `mean_commute_min`
from Source 3. No figure is saved, so `output/` stays empty.

## Who made it, and when

Zachary D. Kline, The College of New Jersey, with help from Claude AI (Anthropic). Last updated
October 26, 2026. Tested with R 4.3.3 and tidyverse 2.0.0 (ggplot2 3.4.4).
