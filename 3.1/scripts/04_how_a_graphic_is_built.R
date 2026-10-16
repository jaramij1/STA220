# scripts/04_how_a_graphic_is_built.R
# Workbook 3.1, "How a Graphic Is Built": Figures 2, 3, and 4.
library(tidyverse)
library(patchwork)    # puts plots side by side
mercer <- read_csv("data/mercer.csv", show_col_types = FALSE)

# --- Figure 2: building a plot one piece at a time --------------------------------------------
code_title <- theme(plot.title = element_text(family = "mono", size = 7.6, face = "plain", lineheight = 1.05),
                    axis.title = element_text(size = 8), axis.text = element_text(size = 7))
s1 <- ggplot(mercer) +
  labs(title = "ggplot(mercer)\n \n \n ") + code_title
print(s1)

s2 <- ggplot(mercer, aes(x = pop, y = budget_m)) +
  labs(title = "ggplot(mercer,\n  aes(x = pop,\n      y = budget_m))\n ") + code_title
print(s2)


s3 <- ggplot(mercer, aes(x = pop, y = budget_m)) +
  geom_point() +
  labs(title = "ggplot(mercer,\n  aes(x = pop,\n      y = budget_m)) +\n  geom_point()") + code_title
print(s3)


ggsave("output/figures/fig02_build.png", s1 + s2 + s3 + plot_layout(widths = c(1, 1, 1)),
       width = 6.5, height = 2.75, dpi = 300, bg = "white")

# --- Figure 3 -----------------
fig03 <- ggplot(mercer, aes(x = pop, y = budget_m)) +
  geom_point()
print(fig03)
ggsave("output/figures/fig03_scatter.png", fig03, width = 4.6, height = 2.9, dpi = 300, bg = "white")

# --- Figure 4 ----------------------------------
fig04 <- ggplot(mercer, aes(x = budget_m, y = town)) +
  geom_col()
print(fig04)
ggsave("output/figures/fig04_bar.png", fig04, width = 4.8, height = 2.75, dpi = 300, bg = "white")
