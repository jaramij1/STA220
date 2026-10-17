# scripts/01_setup.R
# Setup check for Module 3. 

# install once per computer, then put a # in front of this line
install.packages(c("tidyverse", "plotly", "shiny"))

# load everything Module 3 uses
library(tidyverse)
library(plotly)
library(shiny)

# Mercer County in the UFB Database, budget year 2025
mercer <- tribble(
  ~town,                    ~pop, ~budget_m, ~ft_employees,
  "East Windsor township",  30436,     25.3,            97,
  "Ewing township",         35858,     58.1,           255,
  "Hamilton township",      93911,    172.5,           701,
  "Hightstown borough",      5978,      9.3,            NA,
  "Hopewell borough",        1938,      4.5,             7,
  "Hopewell township",      17916,     29.8,           108,
  "Lawrence township",      32388,     58.5,           195,
  "Pennington borough",      2906,      4.8,            17,
  "Princeton borough",      31445,     77.9,           234,
  "Robbinsville township",  15928,     30.6,           127,
  "Trenton city",           91193,    260.8,            NA,
  "West Windsor township",  32241,     53.5,           207
)

# one point for each town
ggplot(mercer, aes(x = pop, y = budget_m)) +
  geom_point() 
