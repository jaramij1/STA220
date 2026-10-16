# scripts/03_know_your_rows.R
# Workbook 3.1, "Know Your Rows": Figure 1, one row makes one mark. (The workbook prints a
# hand-drawn version; this is the same diagram drawn with ggplot.)
library(tidyverse)
ewing <- read_csv("data/ewing.csv", show_col_types = FALSE)

cell_w <- 1.5
row_h  <- 0.55
cells <- bind_rows(
  tibble(i = 0, x = c(0, cell_w), label = c("year", "budget_m"), header = TRUE),
  ewing |> mutate(i = row_number()) |> transmute(i, x = 0, label = as.character(year), header = FALSE),
  ewing |> mutate(i = row_number()) |> transmute(i, x = cell_w, label = format(budget_m, nsmall = 1), header = FALSE)
) |>
  mutate(y = -i * row_h)
bars <- ewing |>
  mutate(i = row_number(), x = 6.2 + (i - 1) * 0.95, height = budget_m / max(budget_m) * 3.0,
         y_row = -i * row_h)

fig01 <- ggplot() +
  geom_tile(data = cells, aes(x = x + cell_w / 2, y = y, fill = header), width = cell_w, height = row_h,
            colour = "grey30", linewidth = 0.4) +
  geom_text(data = filter(cells, header), aes(x = x + cell_w / 2, y = y, label = label),
            family = "mono", size = 3.2, fontface = "bold") +
  geom_text(data = filter(cells, !header), aes(x = x + cell_w / 2, y = y, label = label),
            family = "mono", size = 3.2) +
  geom_rect(data = bars, aes(xmin = x, xmax = x + 0.7, ymin = -3.3, ymax = -3.3 + height),
            fill = "grey55", colour = "grey20") +
  geom_text(data = bars, aes(x = x + 0.35, y = -3.55, label = year), size = 2.9) +
  geom_curve(data = bars, aes(x = 2 * cell_w + 0.1, y = y_row, xend = x + 0.3, yend = -3.3 + height * 0.55),
             curvature = -0.15, arrow = arrow(length = unit(0.18, "cm"), type = "closed"), colour = "grey25",
             linewidth = 0.35) +
  annotate("segment", x = 5.9, xend = 11.3, y = -3.3, yend = -3.3, colour = "black", linewidth = 0.6) +
  annotate("text", x = 1.5, y = 0.6, label = "the ewing table: 5 rows", size = 3.8) +
  annotate("text", x = 8.3, y = 0.6, label = "the bar chart: 5 bars", size = 3.8) +
  annotate("text", x = 4.8, y = 0.75, label = "one row\nmakes one mark", size = 3.8, fontface = "bold") +
  annotate("text", x = 0, y = -3.75, label = "one row = Ewing in one budget year", size = 3, hjust = 0, colour = "grey30") +
  scale_fill_manual(values = c(`TRUE` = "grey85", `FALSE` = "white"), guide = "none") +
  coord_equal(xlim = c(-0.3, 11.5), ylim = c(-4.0, 1.1), expand = FALSE) +
  theme_void()
ggsave("output/figures/fig01_one_row_one_mark.png", fig01, width = 6.5, height = 3.0, dpi = 300, bg = "white")
print(fig01)