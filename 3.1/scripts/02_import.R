# scripts/02_import.R

# NOTE: You do NOT need to learn all of the commands used on this page.
# The code is to reproduce the objects used in the workbook. 
# You can borrow from the commands here but do not need to understand every detail.

# One important command to look at is the left join;
# you will need to do this for your dashboard!



# Reads the User Friendly Budget (UFB) Database and writes the small tables the other scripts use:
#   data/mercer.csv     the 12 Mercer County towns, budget year 2025 (page 3 of the workbook)
#   data/ewing.csv      Ewing township, 2021 to 2025 (page 3)
#   data/colleges.csv   13 New Jersey college towns, budget year 2025 (Practice in R)
#   data/glassboro.csv  Glassboro borough, 2016 to 2025 (Practice in R)
#   data/nj_towns_2016_2025.csv   every town in every year, for the state benchmark (and for 3.3)
#
# data/UFB.xlsm is the database exactly as downloaded from the NJ Department of Community
# Affairs. Never edit it!
library(tidyverse)
library(readxl)

ufb <- "data/UFB.xlsm"

# --- how a Summary sheet is laid out ---------------------------------------------------------
# Row 1 is blank, row 2 is a title, row 3 holds group headers, row 4 holds subgroup headers,
# row 5 holds the column names, and the data start in row 6. The column names repeat ("Total"
# appears many times), so a column is identified by its subgroup header and its name together.
# After the municipalities come a blank row and four summary rows: Minimum, Maximum, Median,
# and Average. Missing values are written as "No data" or "--".
read_ufb <- function(year) {
  sheet <- paste(year, "Summary")
  header <- read_excel(ufb, sheet = sheet, skip = 2, n_max = 3, col_names = FALSE,
                       .name_repair = "minimal")
  subgroup <- vctrs::vec_fill_missing(as.character(header[2, ]), direction = "down")
  name     <- as.character(header[3, ])
  stopifnot(name[1] == "Muni-code")
  full_name <- if_else(is.na(subgroup), name, paste(subgroup, name, sep = " | "))
  out <- read_excel(ufb, sheet = sheet, skip = 5, col_names = full_name,
                    na = c("", "No data", "--"), .name_repair = "minimal") |>
    select(muni_code    = 1,
           municipality = 3,
           county       = 4,
           pop          = matches("^Population and Density \\| .*Population (\\(|Estimate)"),
           land_sqmi    = matches("^Population and Density \\| .*Land Area"),
           budget       = matches("General Budget Appropriations \\| Total General Budget$"),
           state_aid    = matches("Total Anticipated Revenues.*\\| State Aid"),
           ft_employees = matches("^Total Personnel Costs \\| Total Full-Time Employees")) |>
    mutate(year = year, .before = 1)
  stopifnot(ncol(out) == 9)    # each pattern must match exactly one column
  out
}

# --- every town, 2016 to 2025 ------------------------------------------------------------------
# Each year's numbers come from that year's sheet, so read the ten sheets and stack them. Towns
# have a four-character code; the blank row and the summary rows do not.
nj <- map(2016:2025, read_ufb) |>
  list_rbind() |>
  filter(str_length(muni_code) == 4)
count(nj, year)               # 565 towns through 2021, then 564: Pine Valley borough merged into Pine Hill
towns_2025 <- filter(nj, year == 2025)

# --- mercer and ewing (page 3 of the workbook) ---------------------------------------------------
mercer <- towns_2025 |>
  filter(county == "Mercer") |>
  transmute(town         = municipality,
            pop,
            budget_m     = round(budget / 1e6, 1),     # dollars to millions, one decimal
            ft_employees) |>
  arrange(town)

ewing <- nj |>
  filter(municipality == "Ewing township", county == "Mercer", year >= 2021) |>  # names repeat, so
  transmute(year, budget_m = round(budget / 1e6, 1))                              # say the county

# --- colleges and glassboro (Practice in R) --------------------------------------------------------
# 13 towns that host a four-year college. Newark and Jersey City host campuses too, but they are
# many times larger than the rest, and Newark has no 2025 budget in the database.
college_towns <- tribble(
  ~municipality,                    ~county,      ~college,
  "Ewing township",                 "Mercer",     "The College of New Jersey",
  "Princeton borough",              "Mercer",     "Princeton University",
  "New Brunswick city",             "Middlesex",  "Rutgers University",
  "Camden city",                    "Camden",     "Rutgers University-Camden",
  "Glassboro borough",              "Gloucester", "Rowan University",
  "Montclair township",             "Essex",      "Montclair State University",
  "Hoboken city",                   "Hudson",     "Stevens Institute of Technology",
  "Madison borough",                "Morris",     "Drew University",
  "South Orange Village township",  "Essex",      "Seton Hall University",
  "Galloway township",              "Atlantic",   "Stockton University",
  "Union township",                 "Union",      "Kean University",
  "Mahwah township",                "Bergen",     "Ramapo College",
  "West Long Branch borough",       "Monmouth",   "Monmouth University"
)
colleges <- college_towns |>
  left_join(towns_2025, by = c("municipality", "county")) |>   # county too: there are two Union townships
  transmute(town         = municipality,
            college,
            pop,
            land_sqmi    = round(land_sqmi, 1),        # 2020 Census land area, square miles
            budget_m     = round(budget / 1e6, 1),     # 2025 general budget, $ millions
            state_aid_m  = round(state_aid / 1e6, 1),  # state aid, $ millions
            ft_employees = round(ft_employees, 1)) |>
  arrange(town)
stopifnot(nrow(colleges) == 13)

glassboro <- nj |>
  filter(municipality == "Glassboro borough", county == "Gloucester") |>
  transmute(year, budget_m = round(budget / 1e6, 1))

# --- save ------------------------------------------------------------------------------------
write_csv(mercer,    "data/mercer.csv")
write_csv(ewing,     "data/ewing.csv")
write_csv(colleges,  "data/colleges.csv")
write_csv(glassboro, "data/glassboro.csv")
write_csv(nj,        "data/nj_towns_2016_2025.csv")
mercer
ewing
