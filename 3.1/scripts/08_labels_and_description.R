# scripts/08_labels_and_description.R
# Workbook 3.1, "Labels and Description": Figure 9 (the scatterplot with labs()) and Figure 10
# (the labeled bar chart students describe).
library(tidyverse)
mercer <- read_csv("data/mercer.csv", show_col_types = FALSE)

# --- Figure 9: the template, finished ----------------------------------------------------------
fig09 <- ggplot(mercer, aes(x = pop, y = budget_m)) +
  geom_point() +
  labs(
    title    = "Bigger towns tend to have bigger budgets",
    subtitle = "Each point is one of Mercer County's 12 towns",
    x        = "Residents (2024 estimate)",
    y        = "General budget, 2025 ($ millions)",
    caption  = "Source: NJ DCA, User Friendly Budget Database, 2025",
    # alt text does not show on the plot; a Shiny app can pass it to screen readers
    alt      = paste("Scatterplot of the 12 Mercer County towns, residents on the x-axis and 2025 general",
                     "budget in millions on the y-axis. Towns with more residents tend to have bigger budgets;",
                     "Trenton and Hamilton, each above 90,000 residents, have the largest budgets.")
  )
ggsave("output/figures/fig09_labels.png", fig09, width = 5.4, height = 3.6, dpi = 300, bg = "white")

# --- Figure 10: a labeled bar chart to describe -----------------------------------------------
fig10 <- ggplot(mercer, aes(x = budget_m, y = town)) +
  geom_col() +
  labs(title   = "Trenton and Hamilton budget more than the other ten towns combined",
       x       = "General budget, 2025 ($ millions)",
       y       = NULL,
       caption = "Source: NJ DCA, User Friendly Budget Database, 2025") +
  theme(plot.title.position = "plot", plot.title = element_text(size = 10.5))
ggsave("output/figures/fig10_bar_labeled.png", fig10, width = 5.4, height = 3.5, dpi = 300, bg = "white")
