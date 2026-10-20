# scripts/01_import.R
# load packages
library(tidyverse)
library(readxl)

ufb <- "data/UFB.xlsm"


# similar function to from 3.1 workbook
read_ufb_activity <- function(year) {
  sheet <- paste(year, "Summary")
  header <- read_excel(ufb, sheet = sheet, skip = 2, n_max = 3, col_names = FALSE,
                       .name_repair = "minimal")
  subgroup <- vctrs::vec_fill_missing(as.character(header[2, ]), direction = "down")
  name     <- as.character(header[3, ])
  stopifnot(name[1] == "Muni-code")
  full_name <- if_else(is.na(subgroup), name, paste(subgroup, name, sep = " | "))
  out <- read_excel(ufb, sheet = sheet, skip = 5, col_names = full_name,
                    na = c("", "No data", "--"), .name_repair = "minimal") |>
    select(muni_code      = 1,
           municipality   = 3,
           county         = 4,
           pop            = matches("^Population and Density \\| (\\d{4} )?Population"),
           land_sqmi      = matches("^Population and Density \\| .*Land Area"),
           budget         = matches("General Budget Appropriations \\| Total General Budget$"),
           local_tax      = matches("Total Anticipated Revenues.*\\| Local Tax for Municipal Purposes"),
           state_aid      = matches("Total Anticipated Revenues.*\\| State Aid"),
           surplus        = matches("Total Anticipated Revenues.*\\| Surplus$"),
           rev_total      = matches("Total Anticipated Revenues.*\\| Total$"),
           ft_employees   = matches("^Total Personnel Costs \\| Total Full-Time Employees"),
           police_ft      = matches("^Police Officer Personnel Costs \\| .*# of Full-Time"),
           police_cost    = matches("^Police Officer Personnel Costs \\| .*Total Personnel Cost"),
           app_pub_safety = matches("General Budget Appropriations \\| Public Safety"),
           app_pub_works  = matches("General Budget Appropriations \\| Public Works"),
           app_parks      = matches("General Budget Appropriations \\| Parks and Recreation"),
           app_debt       = matches("General Budget Appropriations \\| Debt$"),
           net_debt_pc    = matches("^Net Debt \\| Per Capita Net Debt"),
           gov_body_cost  = matches("^Governing Body Personnel Costs \\| .*Total Personnel Cost")) |>
    mutate(year = year, .before = 1)
  stopifnot(ncol(out) == 20)    # each pattern must match exactly one column
  out
}

# Towns have a four-character code; the blank row and the summary rows do not.
nj_activity <- map(2016:2025, read_ufb_activity) |>
  list_rbind() |>
  filter(str_length(muni_code) == 4) |>
  mutate(across(pop:gov_body_cost, as.numeric),     # "No data" became NA, so every column is numeric
         land_sqmi   = round(land_sqmi, 2),
         net_debt_pc = round(net_debt_pc))
count(nj_activity, year)

# CPI Source: U.S. Bureau of Labor Statistics. 
cpi_u <- tibble(
  year  = 2016:2025,
  cpi_u = c(240.007, 245.120, 251.107, 255.657, 258.811, 270.970, 292.655, 304.702, 313.689, 321.943)
)

write_csv(nj_activity, "data/ufb_activity_2016_2025.csv")
write_csv(cpi_u,       "data/cpi_u_2016_2025.csv")
