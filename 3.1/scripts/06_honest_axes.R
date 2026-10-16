# scripts/06_honest_axes.R
library(tidyverse)
library(patchwork)
ewing <- read_csv("data/ewing.csv", show_col_types = FALSE)
two_years <- filter(ewing, year >= 2024)

# --- Figure 6 -------------------------------------------------------------
small <- theme(plot.title = element_text(size = 8.5, face = "bold"), axis.title = element_text(size = 8.5),
               axis.text = element_text(size = 8))
xs <- scale_x_continuous(breaks = c(2024, 2025), limits = c(2023.4, 2025.6))

# A. bars from zero
c1 <- ggplot(two_years, aes(x = year, y = budget_m)) +
  geom_col(width = 0.6) + xs +
  labs(title = "A. Bars from zero", x = NULL, y = "Budget ($ millions)") + small
print(c1)

# B. the same bars with the axis cut at 55. coord_cartesian() zooms the axis without dropping the bars.
c2 <- ggplot(two_years, aes(x = year, y = budget_m)) +
  geom_col(width = 0.6) + xs +
  coord_cartesian(ylim = c(55, 60), expand = FALSE) +
  labs(title = "B. Bars, cut at 55", x = NULL, y = "Budget ($ millions)") + small
print(c2)

# C. points on the same axis as B
c3 <- ggplot(two_years, aes(x = year, y = budget_m)) +
  geom_point(size = 2.6) + xs +
  scale_y_continuous(limits = c(55, 60)) +
  labs(title = "C. Points, same axis", x = NULL, y = "Budget ($ millions)") + small
print(c3)

ggsave("output/figures/fig06_cut_axis.png", c1 + c2 + c3, width = 6.5, height = 2.6, dpi = 300, bg = "white")

# --- Figure 7  ----------------------
mono_title <- theme(plot.title = element_text(family = "mono", size = 9))
e1 <- ggplot(ewing, aes(x = year, y = budget_m)) +
  geom_col() +
  labs(title = "geom_col()") + mono_title
print(e1)


e2 <- ggplot(ewing, aes(x = year, y = budget_m)) +
  geom_point() +
  labs(title = "geom_point()") + mono_title
print(e2)
ggsave("output/figures/fig07_defaults.png", e1 + e2, width = 6.3, height = 2.6, dpi = 300, bg = "white")
