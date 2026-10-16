# scripts/07_what_the_eye_compares.R
# Workbook 3.1, "Doth My Eyes Deceive Me?": Figure 8, two values shown five ways. The smaller
# value as a percent of the larger is 65, 40, 30, 55, and 75.
library(tidyverse)
library(patchwork)

# every panel is a 10 by 10 square with a thin border and a title in the corner
panel <- function(title) {
  list(annotate("text", x = 0.45, y = 9.25, label = title, hjust = 0, size = 3.5, fontface = "bold"),
       coord_equal(xlim = c(0, 10), ylim = c(0, 10), expand = FALSE),
       theme_void(),
       theme(panel.border = element_rect(fill = NA, colour = "grey50", linewidth = 0.4),
             plot.margin = margin(2, 2, 2, 2)))
}
# points on the edge of a circle or a wedge, for drawing with geom_polygon
arc <- function(cx, cy, r, from = 0, to = 360, wedge = FALSE) {
  a <- seq(from, to, length.out = 60) * pi / 180
  d <- tibble(x = cx + r * cos(a), y = cy + r * sin(a))
  if (wedge) d <- bind_rows(tibble(x = cx, y = cy), d, tibble(x = cx, y = cy))
  d
}
ink <- "grey35"

# A. position on a common scale: 80 and 52
pA <- ggplot() +
  annotate("segment", x = 2.6, xend = 2.6, y = 1.2, yend = 8.2, linewidth = 0.6) +
  annotate("segment", x = 2.35, xend = 2.6, y = c(1.2, 8.2), yend = c(1.2, 8.2), linewidth = 0.6) +
  annotate("text", x = 2.15, y = c(1.2, 8.2), label = c("0", "100"), hjust = 1, size = 2.8) +
  annotate("segment", x = 2.6, xend = 8.6, y = 1.2, yend = 1.2, linewidth = 0.4) +
  annotate("point", x = c(4.6, 7.2), y = 1.2 + 7 * c(80, 52) / 100, size = 2.6) +
  panel("A. Position")

# B. length with no shared baseline: 90 and 36
pB <- ggplot() +
  annotate("rect", xmin = 0.9, xmax = 0.9 + 90 * 0.085, ymin = 5.9, ymax = 6.8, fill = ink, colour = "black", linewidth = 0.3) +
  annotate("rect", xmin = 4.3, xmax = 4.3 + 36 * 0.085, ymin = 2.6, ymax = 3.5, fill = ink, colour = "black", linewidth = 0.3) +
  panel("B. Length")

# C. angle: 150 and 45 degrees
pC <- ggplot() +
  geom_polygon(data = arc(3.0, 4.3, 2.3, 20, 170, wedge = TRUE), aes(x, y), fill = ink, colour = "black", linewidth = 0.3) +
  geom_polygon(data = arc(6.2, 2.2, 2.3, 15, 60, wedge = TRUE), aes(x, y), fill = ink, colour = "black", linewidth = 0.3) +
  panel("C. Angle")

# D. area: 100 and 55. The smaller circle has 55 percent of the area, so its radius is sqrt(0.55) times as long.
pD <- ggplot() +
  geom_polygon(data = arc(3.2, 4.4, 2.45), aes(x, y), fill = ink, colour = "black", linewidth = 0.3) +
  geom_polygon(data = arc(7.6, 3.0, 2.45 * sqrt(0.55)), aes(x, y), fill = ink, colour = "black", linewidth = 0.3) +
  panel("D. Area")

# E. shade: 80 percent black and 60 percent black, with the scale underneath
strip <- tibble(x = seq(1.3, 8.7, length.out = 200), shade = seq(0, 100, length.out = 200))
pE <- ggplot() +
  geom_tile(data = strip, aes(x = x, y = 1.675, fill = shade), width = 7.4 / 199 + 0.02, height = 0.65) +
  annotate("rect", xmin = 1.3, xmax = 8.7, ymin = 1.35, ymax = 2.0, fill = NA, colour = "black", linewidth = 0.3) +
  annotate("rect", xmin = 1.3, xmax = 4.2, ymin = 3.9, ymax = 6.8, fill = grey(1 - 0.80), colour = "black", linewidth = 0.3) +
  annotate("rect", xmin = 5.8, xmax = 8.7, ymin = 3.9, ymax = 6.8, fill = grey(1 - 0.60), colour = "black", linewidth = 0.3) +
  annotate("text", x = c(1.3, 8.7), y = 0.8, label = c("0", "100"), size = 2.6) +
  annotate("text", x = 5.0, y = 0.8, label = "white = 0, black = 100", size = 1.9, colour = "grey25") +
  scale_fill_gradient(low = "white", high = "black", limits = c(0, 100), guide = "none") +
  panel("E. Color (shade)")

fig08 <- (pA | pB | pC) / (plot_spacer() | pD | pE | plot_spacer()) +
  plot_layout(widths = c(1, 1, 1))
print(fig08)


ggsave("output/figures/fig08_experiment.png", fig08, width = 6.5, height = 4.5, dpi = 300, bg = "white")
