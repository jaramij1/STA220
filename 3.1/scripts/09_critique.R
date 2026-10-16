# scripts/09_critique.R
# Workbook 3.1, "Critiquing a Graphic": Figure 11 ("Ewing's budget is exploding!") and Figure 12
# ("Ewing far outspends West Windsor"), plus the state benchmark the critique quotes.
library(tidyverse)
mercer <- read_csv("data/mercer.csv", show_col_types = FALSE)
ewing  <- read_csv("data/ewing.csv",  show_col_types = FALSE)
two_years <- filter(ewing, year >= 2024)

# a newsletter look: no grid, bold title, black bars
pub <- theme_classic(base_size = 10) +
  theme(plot.title = element_text(face = "bold", size = 15), plot.subtitle = element_text(size = 9.5),
        plot.title.position = "plot")

# --- Figure 11: the worked example ------------------------------------------------------------
fig11 <- ggplot(two_years, aes(x = year, y = budget_m)) +
  geom_col(width = 0.55, fill = "black") +
  scale_x_continuous(breaks = c(2024, 2025), limits = c(2023.4, 2025.6)) +
  scale_y_continuous(breaks = 55:59) +
  coord_cartesian(ylim = c(55, 59), expand = FALSE) +
  labs(title = "Ewing's budget is exploding!", subtitle = "Millions of dollars", x = NULL, y = NULL) +
  pub
ggsave("output/figures/fig11_exploding.png", fig11, width = 3.6, height = 3.0, dpi = 300, bg = "white")

# --- Figure 12: Ewing and West Windsor ----------------------------------------------------------
ew <- mercer |>
  filter(town %in% c("Ewing township", "West Windsor township")) |>
  mutate(town = c("Ewing", "West Windsor"))
fig12 <- ggplot(ew, aes(x = town, y = budget_m)) +
  geom_col(width = 0.55, fill = "black") +
  scale_y_continuous(breaks = seq(50, 60, 2)) +
  coord_cartesian(xlim = c(0.4, 2.6), ylim = c(50, 60), expand = FALSE) +
  labs(title = "Ewing far outspends West Windsor", subtitle = "2025 budget, millions of dollars", x = NULL, y = NULL) +
  pub + theme(plot.title = element_text(face = "bold", size = 12.5))
ggsave("output/figures/fig12_ewing_west_windsor.png", fig12, width = 3.6, height = 3.0, dpi = 300, bg = "white")

# --- the state benchmark quoted in the critique --------------------------------------------------
# Among New Jersey towns with a general budget in both 2024 and 2025, the median growth was 4.1 percent.
nj <- read_csv("data/nj_towns_2016_2025.csv", show_col_types = FALSE)
nj |>
  filter(year %in% c(2024, 2025), !is.na(budget), budget > 0) |>
  select(muni_code, year, budget) |>
  pivot_wider(names_from = year, values_from = budget, names_prefix = "y") |>
  filter(!is.na(y2024), !is.na(y2025)) |>
  summarize(towns = n(), median_growth_pct = median((y2025 - y2024) / y2024 * 100))
