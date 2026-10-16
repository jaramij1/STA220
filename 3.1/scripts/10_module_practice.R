# scripts/10_module_practice.R
# Workbook 3.1, "Module 3.1 Practice": Figure 13 (an honest chart of ewing to describe), Figure 14
# (the circles to critique), and the blank axes for the newsletter question.
library(tidyverse)
mercer <- read_csv("data/mercer.csv", show_col_types = FALSE)
ewing  <- read_csv("data/ewing.csv",  show_col_types = FALSE)

# --- Figure 13: an honest chart of ewing -----------------------------------------------------
fig13 <- ggplot(ewing, aes(x = year, y = budget_m)) +
  geom_col() +
  labs(title   = "Ewing's budget has grown every year since 2021",
       x       = "Budget year",
       y       = "General budget ($ millions)",
       caption = "Source: NJ DCA, User Friendly Budget Database, 2021 to 2025")
ggsave("output/figures/fig13_ewing_five_years.png", fig13, width = 4.8, height = 3.3, dpi = 300, bg = "white")

# --- Figure 14: circles whose WIDTH matches the budget ------------------------------------------
three <- mercer |>
  filter(town %in% c("Hamilton township", "Ewing township", "Hightstown borough")) |>
  mutate(name = str_remove(town, " township| borough"),
         x = c(6.75, 2.6, 9.15)[match(name, c("Ewing", "Hamilton", "Hightstown"))],
         diameter = 4.3 * budget_m / max(budget_m))           # Hamilton's circle is 4.3 units wide
circle <- function(cx, cy, r) {
  a <- seq(0, 2 * pi, length.out = 120)
  tibble(x = cx + r * cos(a), y = cy + r * sin(a))
}
circles <- three |>
  rowwise() |>
  reframe(name, circle(x, 0.95 + diameter / 2, diameter / 2))
fig14 <- ggplot() +
  geom_polygon(data = circles, aes(x = x, y = y, group = name), fill = "black") +
  geom_text(data = three, aes(x = x, y = 0.5, label = name), size = 3.3) +
  annotate("text", x = 0.35, y = 6.05, label = "Hamilton's giant budget", hjust = 0, size = 4.8, fontface = "bold") +
  annotate("text", x = 0.35, y = 5.5, label = "2025 general budget", hjust = 0, size = 3.3) +
  coord_equal(xlim = c(0, 10.4), ylim = c(0, 6.6), expand = FALSE) +
  theme_void()
ggsave("output/figures/fig14_circles.png", fig14, width = 5.2, height = 3.3, dpi = 300, bg = "white")

# --- blank axes for drawing the newsletter's two bars honestly -----------------------------------
grid_theme <- theme_bw(base_size = 10) +
  theme(panel.grid.major = element_line(colour = "grey55", linewidth = 0.35),
        panel.grid.minor = element_line(colour = "grey82", linewidth = 0.25))
blank_bars <- ggplot(tibble(year = c("2024", "2025"), v = c(0, 0)), aes(x = year, y = v)) +
  geom_blank() +
  scale_y_continuous(limits = c(0, 80000), breaks = seq(0, 80000, 20000), minor_breaks = seq(0, 80000, 10000),
                     labels = scales::comma, expand = c(0, 0)) +
  labs(x = "Year", y = "Visitors") + grid_theme + theme(plot.margin = margin(8, 14, 6, 6))
ggsave("output/figures/grid_bars.png", blank_bars, width = 3.4, height = 3.0, dpi = 300, bg = "white")
