# scripts/12_practice_solutions.R
# One way to make each figure in scripts/11_practice_in_r.R. Try the tasks on your own first.
library(tidyverse)
colleges  <- read_csv("data/colleges.csv",  show_col_types = FALSE)
glassboro <- read_csv("data/glassboro.csv", show_col_types = FALSE)

# ---- Task 1. Land and people ---------------------------------------------------------------
t1 <- ggplot(colleges, aes(x = land_sqmi, y = pop)) +
  geom_point() +
  theme_minimal()
print(t1)
ggsave("output/figures/practice1_land_pop.png", t1)

# ---- Task 2. State aid ---------------------------------------------------------------------
t2 <- ggplot(colleges, aes(x = state_aid_m, y = town)) +
  geom_col()+
  theme_minimal()
print(t2)
ggsave("output/figures/practice2_state_aid.png", t2)

# ---- Task 3. Glassboro's budget over time --------------------------------------------------
t3_points <- ggplot(glassboro, aes(x = year, y = budget_m)) +
  geom_point() +
  scale_x_continuous(breaks = 2016:2025)+
  theme_minimal()
print(t3_points)

t3_bars <- ggplot(glassboro, aes(x = year, y = budget_m)) +
  geom_col() +
  scale_x_continuous(breaks = 2016:2025)+
  theme_minimal()
print(t3_bars)

ggsave("output/figures/practice3_points.png", t3_points)
ggsave("output/figures/practice3_bars.png",   t3_bars)

# ---- Task 4. Budget per resident -------------------------------------------------------------
colleges2 <- colleges |>
  mutate(budget_per_resident = budget_m * 1000000 / pop)
t4 <- ggplot(colleges2, aes(x = budget_per_resident, y = town)) +
  geom_col()+
  theme_minimal()
print(t4)

ggsave("output/figures/practice4_budget_per_resident.png", t4)

# ---- Task 5. Labels-----------------------------------------------------------
t5 <- ggplot(colleges2, aes(x = budget_per_resident, y = town)) +
  geom_col() +
  labs(
    title    = "Camden budgets the most per resident",
    subtitle = "Each bar is one town with a four-year college",
    x        = "General budget per resident, 2025 (dollars)",
    y        = "Town",
    caption  = "Source: NJ DCA, User Friendly Budget Database, 2025"
  )  +
  theme_minimal()
print(t5)

ggsave("output/budget_per_resident.png", t5)
ggsave("output/figures/practice5_labeled.png", t5)
