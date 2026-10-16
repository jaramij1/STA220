# scripts/05_scales.R

library(tidyverse)
mercer <- read_csv("data/mercer.csv", show_col_types = FALSE)

# where a value lands on a linear axis, as a fraction of the way along it
position <- function(value, axis_min, axis_max) (value - axis_min) / (axis_max - axis_min)

# --- Figure 5: the scale decides where a number lands ----------------------------------------
one_axis <- function(x, axis_min, axis_max, value, title, note) {
  ticks <- tibble(v = seq(axis_min, axis_max, length.out = 11),
                  y = seq(0, 4, length.out = 11),
                  long = v %in% c(axis_min, (axis_min + axis_max) / 2, axis_max))
  y_val <- 4 * position(value, axis_min, axis_max)
  list(
    annotate("segment", x = x, xend = x, y = 0, yend = 4, linewidth = 0.8),
    annotate("segment", x = x - if_else(ticks$long, 0.22, 0.12), xend = x, y = ticks$y, yend = ticks$y, linewidth = 0.5),
    annotate("text", x = x - 0.35, y = c(0, 2, 4), label = format(c(axis_min, (axis_min + axis_max) / 2, axis_max), big.mark = ","),
             hjust = 1, size = 3, family = "mono", colour = c("black", "grey45", "black")),
    annotate("segment", x = x, xend = x + 0.4, y = y_val, yend = y_val, linetype = "dashed", colour = "grey45"),
    annotate("point", x = x + 0.4, y = y_val, size = 3.5),
    annotate("text", x = x + 0.7, y = y_val + 0.05, label = "Ewing", hjust = 0, size = 4, fontface = "bold"),
    annotate("text", x = x + 0.7, y = y_val - 0.3, label = value, hjust = 0, size = 3, family = "mono"),
    annotate("text", x = x + 0.7, y = y_val - 0.65, label = note, hjust = 0, size = 3.3, colour = "grey25"),
    annotate("text", x = x + 0.4, y = 4.6, label = title, size = 3.8)
  )
}
fig05 <- ggplot() +
  one_axis(2.3, 0, 300, 58.1, "axis from 0 to 300", "0.19 of the way up") +
  one_axis(8.9, 50, 60, 58.1, "axis from 50 to 60", "0.81 of the way up") +
  annotate("text", x = 5.6, y = 3.0, label = "same town,\nsame budget,\ndifferent place\non the page", size = 3.8,
           colour = "grey25", lineheight = 0.95) +
  coord_equal(xlim = c(0, 13), ylim = c(-0.6, 5.2), expand = FALSE) +
  theme_void()
print(fig05)
ggsave("output/figures/fig05_scale.png", fig05, width = 6.5, height = 2.9, dpi = 300, bg = "white")

# --- the blank axis from 0 to 300 (Practice: Scales) --------------------------------------------
ticks <- tibble(v = seq(0, 300, 5)) |>
  mutate(len = case_when(v %% 50 == 0 ~ 0.42, v %% 25 == 0 ~ 0.28, TRUE ~ 0.14),
         lwd = case_when(v %% 50 == 0 ~ 0.6, v %% 25 == 0 ~ 0.4, TRUE ~ 0.3))
number_line <- ggplot(ticks) +
  annotate("segment", x = 0, xend = 300, y = 0, yend = 0, linewidth = 0.8) +
  geom_segment(aes(x = v, xend = v, y = 0, yend = len, linewidth = lwd)) +
  scale_linewidth_identity() +
  annotate("text", x = c(0, 150, 300), y = -0.5, label = c("0", "General budget, 2025 ($ millions)", "300"), size = 3.2) +
  coord_cartesian(xlim = c(-27, 327), ylim = c(-1, 1.6), expand = FALSE) +
  theme_void()
print(number_line)
ggsave("output/figures/grid_number_line.png", number_line, width = 6.0, height = 1.15, dpi = 300, bg = "white")

# --- the blank grid for plotting four towns by hand ----------------------------------------------
grid_theme <- theme_bw(base_size = 10) +
  theme(panel.grid.major = element_line(colour = "grey55", linewidth = 0.35),
        panel.grid.minor = element_line(colour = "grey82", linewidth = 0.25))
blank_scatter <- ggplot(mercer, aes(x = pop, y = budget_m)) +
  geom_blank() +
  scale_x_continuous(limits = c(0, 100000), breaks = seq(0, 100000, 20000), minor_breaks = seq(0, 100000, 10000),
                     labels = scales::comma, expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 300), breaks = seq(0, 300, 50), minor_breaks = seq(0, 300, 25), expand = c(0, 0)) +
  labs(x = "Residents (2024 estimate)", y = "General budget, 2025 ($ millions)") +
  grid_theme + theme(plot.margin = margin(8, 16, 6, 6))
print(blank_scatter)
ggsave("output/figures/grid_scatter.png", blank_scatter, width = 5.8, height = 3.9, dpi = 300, bg = "white")
