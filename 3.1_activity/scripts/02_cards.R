# scripts/02_cards.R

library(tidyverse)
nj  <- read_csv("data/ufb_activity_2016_2025.csv", show_col_types = FALSE,
                col_types = cols(muni_code = col_character()))  
cpi <- read_csv("data/cpi_u_2016_2025.csv", show_col_types = FALSE)

# set where to send figures
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

# --- inflation adjustment ------------------------------------------------------------------------
# merge cpi 
cpi_2025 <- cpi$cpi_u[cpi$year == 2025]
nj <- nj |>
  left_join(cpi, by = "year") |>
  mutate(to_2025 = cpi_2025 / cpi_u)

# Mercer County, 2025, keeping shortened names for labels
mercer <- nj |>
  filter(county == "Mercer", year == 2025) |>
  mutate(short = case_when(municipality == "Hopewell borough"  ~ "Hopewell boro",
                           municipality == "Hopewell township" ~ "Hopewell twp",
                           TRUE ~ str_remove(municipality, " township| borough| city")))
ewing    <- filter(nj, muni_code == "1102")
hamilton <- filter(nj, muni_code == "1103")

# the newsletter look from workbook 3.1
# NOTE: You can also use theme_minimal in place of "pub"
# theme_minimal is my preference in academic publications
# However, it doesn't look as good on word. 
# Feel free to explore other styles too!

pub <- theme_classic(base_size = 10) +
  theme(plot.title = element_text(face = "bold", size = 13), plot.subtitle = element_text(size = 8.5),
        plot.caption = element_text(size = 7, hjust = 0, color = "grey30"), plot.title.position = "plot",
        plot.caption.position = "plot")
save_card <- function(plot, name, width = 4.4, height = 3.2) {
  ggsave(paste0("output/figures/", name, ".png"), plot, width = width, height = height,
         dpi = 300, bg = "white")
}
source <- "Source: NJ DCA, User Friendly Budget Database"

# --- Card 1  ---------------------
card1 <- ewing |>
  mutate(levy_pr_real = local_tax * to_2025 / pop) |>
  ggplot(aes(x = year, y = levy_pr_real)) +
  geom_col(fill = "black", width = 0.7) +
  scale_x_continuous(breaks = 2016:2025) +
  scale_y_continuous(limits = c(0, 1200), breaks = seq(0, 1200, 300), expand = c(0, 0)) +
  labs(title = "Other towns cut. Ewing didn't.",
       subtitle = "Ewing's municipal tax levy per resident, in 2025 dollars (CPI).\nTypical NJ town: $1,150 in 2016, $1,045 in 2025, in 2025 dollars.",
       x = NULL, y = "Municipal tax per resident, 2025 dollars",
       caption = paste(source, "2016 to 2025; U.S. BLS, CPI annual averages", sep = ", ")) +
  pub
save_card(card1, "card1_ewing_real_levy")
print(card1)

# --- Card 2  ---------

card2 <- hamilton |>
  ggplot(aes(x = year, y = local_tax / 1e6)) +
  geom_col(fill = "black", width = 0.7) +
  scale_x_continuous(breaks = 2016:2025) +
  scale_y_continuous(limits = c(0, 125), breaks = seq(0, 125, 25), expand = c(0, 0)) +
  labs(title = "Hamilton's municipal taxes nearly DOUBLED since 2016",
       subtitle = "Municipal-purpose property tax levy, millions of dollars.\n2016: $63.2 million. 2025: $118.2 million. Up 87 percent.",
       x = NULL, y = "Millions of dollars") +
  pub
save_card(card2, "card2_hamilton_levy")
print(card2)


# --- Card 3  -------------------------------------------
# drop towns with 0 reported police or NA
police <- mercer |>
  filter(!is.na(police_ft), police_ft > 0) |> 
  mutate(per_1000 = police_ft / pop * 1000)

card3 <- ggplot(police, aes(x = per_1000, y = fct_reorder(short, per_1000), fill = short == "Ewing")) +
  geom_col(width = 0.65) +
  geom_text(aes(label = sprintf("%.1f", per_1000)), hjust = -0.4, size = 5) + # adds the numbers after the bars 
  scale_fill_manual(values = c("black", "firebrick"), guide = "none") +
  scale_x_continuous(limits = c(0, 3), breaks = 0:3, expand = c(0, 0)) +
  labs(title = "Ewing has the most police per resident in Mercer County",
       subtitle = "Full-time officers, 2025. Hopewell borough reported force of size 0;\nTrenton and Hightstown did not report a count.",
       x = "Full-time police officers per 1,000 residents", y = NULL,
       caption = paste(source, "2025 sheet (officers and population as reported)", sep = ", ")) +
  pub
save_card(card3, "card3_police_per_1000")
print(card3)

# --- Card 4  ----------------------

# Keep only 5 (and don't explain why!)
five <- mercer |>
  filter(short %in% c("Ewing", "Lawrence", "West Windsor", "Princeton", "East Windsor"))

# create figure
card4 <- ggplot(five, aes(x = police_cost / 1e6, y = fct_reorder(short, police_cost), fill = short == "Ewing")) +
  geom_col(width = 0.6) +
  scale_fill_manual(values = c("black", "firebrick"), guide = "none") +
  scale_x_continuous(breaks = 7:14) +
  coord_cartesian(xlim = c(7, 14), expand = FALSE) +
  labs(title = "Ewing's police payroll is the fattest in the county",
       subtitle = "Police personnel cost, 2025, millions of dollars", x = NULL, y = NULL) +
  pub
save_card(card4, "card4_police_cost_cut")
print(card4)

# --- Card 5 -------------------------------------

# calculate aid state aid per pop
aid <- mutate(mercer, aid_pr = state_aid / pop)


card5 <- ggplot(aid, aes(x = aid_pr, y = fct_reorder(short, aid_pr), fill = short == "Trenton")) +
  geom_col(width = 0.65) +
  geom_text(aes(label = scales::dollar(round(aid_pr))), hjust = -0.15, size = 5) +
  scale_fill_manual(values = c("black", "firebrick"), guide = "none") +
  scale_x_continuous(limits = c(0, 1400), breaks = seq(0, 1250, 250), expand = c(0, 0)) +
  labs(title = "Trenton collects $1,208 per resident in state aid!\n!lmost five times second place! ",
       subtitle = "State aid in the 2025 budget, divided by residents",
       x = "State aid per resident, dollars", y = NULL, caption = paste(source, "2025 sheet", sep = ", ")) +
  pub
save_card(card5, "card5_state_aid", width = 4.6, height = 3.4)
print(card5)

# --- Card 6  ----------------------------------------

# Surplus
surp <- mutate(mercer, pct = surplus / rev_total * 100)

card6 <- ggplot(surp, aes(x = pct, y = fct_reorder(short, pct), fill = short == "West Windsor")) +
  geom_col(width = 0.65) +
  geom_text(aes(label = sprintf("%.0f%%", pct)), hjust = -0.2, size = 5) +
  scale_fill_manual(values = c("black", "firebrick"), guide = "none") +
  scale_x_continuous(limits = c(0, 30), breaks = seq(0, 30, 10), expand = c(0, 0)) +
  labs(title = "West Windsor is sitting on a surplus worth 25% of its revenue!",
       subtitle = "The \"Surplus\" line of each town's 2025 budget as a share of its total anticipated revenue",
       x = "Surplus as a percent of total revenue, 2025", y = NULL, caption = paste(source, "2025 sheet", sep = ", ")) +
  pub
save_card(card6, "card6_surplus")
print(card6)

# --- Card 7  ------------------------------------
card7 <- ggplot(ewing, aes(x = year, y = net_debt_pc)) +
  geom_line() +
  geom_point(size = 1.6) +
  geom_text(data = filter(ewing, year %in% c(2016, 2020, 2025)),
            aes(label = scales::dollar(net_debt_pc)), vjust = -0.9, size = 5) +
  scale_x_continuous(breaks = 2016:2025) +
  scale_y_continuous(limits = c(0, 1900), breaks = seq(0, 1500, 500), expand = c(0, 0)) +
  labs(title = "Ewing's debt per resident has nearly tripled since 2016!!",
       subtitle = "Net debt ÷ residents, in the dollars of each year (not adjusted for inflation). Ewing did not report 2021.",
       x = NULL, y = "Net debt per resident, dollars",
       caption = paste(source, "2016 to 2025 sheets (\"Per Capita Net Debt\")", sep = ", ")) +
  pub
save_card(card7, "card7_ewing_debt")
print(card7)

# --- Card 8 
# ggplot doesn't have a natural circle geom
circle <- function(center_x, center_y, radius) {
  a <- seq(0, 2 * pi, length.out = 120)
  tibble(
    x = center_x + radius * cos(a), 
    y = center_y + radius * sin(a))
}

# limit to ewing and Hamilton and calculate radius
two <- mercer |>
  filter(short %in% c("Ewing", "Hamilton")) |>
  mutate(x = if_else(short == "Ewing", 0.9, 3.9),
         r = 0.4 * gov_body_cost / gov_body_cost[short == "Ewing"],   # Ewing's circle has radius 0.4
         label = paste0(short, "\n", scales::dollar(gov_body_cost)))

# draw the circles; hint: try playing with the length.out for the circle() function!
circles <- two |>
  rowwise() |>
  reframe(short, circle(x, 1.0, r))

card8 <- ggplot() +
  geom_polygon(data = circles, aes(x = x, y = y, group = short), fill = "black") +
  geom_text(data = two, aes(x = x, y = 1.0 - r - 0.25, label = label), vjust = 1, size = 2.8) +
  annotate("text", x = 0, y = 3.45, label = "Hamilton's council costs more than 3x Ewing's",
           hjust = 0, vjust = 1, size = 4.3, fontface = "bold", lineheight = 0.9) +
  annotate("text", x = 0, y = 3.25, label = "Governing body personnel cost, 2025", hjust = 0, vjust = 1, size = 3) +
  coord_equal(xlim = c(0, 5.6), ylim = c(-1.0, 3.5), expand = FALSE) +
  theme_void()
save_card(card8, "card8_council_circles")
print(card8)

# ---  benchmarks (printed on the cards and/or handouts) -------------------------------------------

t25 <- filter(nj, year == 2025, !is.na(budget), budget > 0, !is.na(pop), pop > 0)

t25 |> summarize(towns = n(), budget_per_resident = median(budget / pop))                   # about $1,679
t25 |> filter(!is.na(ft_employees), ft_employees > 0, ft_employees < 5000) |>              # one town reports 181818
  summarize(towns = n(), ft_per_1000 = median(ft_employees / pop * 1000))                   # about 5.8
t25 |> filter(!is.na(police_ft), police_ft > 0) |>
  summarize(towns = n(), officers_per_1000 = median(police_ft / pop * 1000),               # about 2.4
            cost_per_officer = median(police_cost / police_ft))                             # about $190,000
t25 |> filter(!is.na(state_aid)) |> summarize(towns = n(), aid_per_resident = median(state_aid / pop))   # about $95
t25 |> filter(!is.na(surplus), rev_total > 0) |> summarize(towns = n(), surplus_pct = median(surplus / rev_total * 100))  # about 12%
t25 |> filter(!is.na(net_debt_pc), net_debt_pc >= 0) |> summarize(towns = n(), net_debt_pc = median(net_debt_pc))     # about $1,345

# the typical town's municipal levy per resident, in 2025 dollars, by year: $1,150 (2016) to $1,045 (2025)
nj |>
  filter(!is.na(local_tax), local_tax > 0, !is.na(pop), pop > 0) |>
  group_by(year) |>
  summarize(towns = n(), levy_per_resident_2025_dollars = median(local_tax * to_2025 / pop))

# the typical town's real per-resident change, 2016 to 2025: levy about -8%, net debt about -10%
nj |>
  filter(year %in% c(2016, 2025), !is.na(local_tax), local_tax > 0, !is.na(pop), pop > 0) |>
  transmute(muni_code, year, levy_pr_real = local_tax * to_2025 / pop) |>
  pivot_wider(names_from = year, values_from = levy_pr_real, names_prefix = "y") |>
  filter(!is.na(y2016), !is.na(y2025)) |>
  summarize(towns = n(), median_real_change_pct = median((y2025 - y2016) / y2016 * 100))

nj |>
  filter(year %in% c(2016, 2025), !is.na(net_debt_pc), net_debt_pc > 0) |>
  transmute(muni_code, year, debt_real = net_debt_pc * to_2025) |>
  pivot_wider(names_from = year, values_from = debt_real, names_prefix = "y") |>
  filter(!is.na(y2016), !is.na(y2025)) |>
  summarize(towns = n(), median_real_change_pct = median((y2025 - y2016) / y2016 * 100))

# Mercer County, 2025, the per-resident and per-officer numbers 
mercer |>
  transmute(short, pop,
            budget_per_resident = round(budget / pop),
            levy_per_resident   = round(local_tax / pop),
            officers_per_1000   = round(police_ft / pop * 1000, 2),
            cost_per_officer    = round(police_cost / police_ft),
            aid_per_resident    = round(state_aid / pop),
            surplus_pct         = round(surplus / rev_total * 100, 1),
            net_debt_pc,
            council_per_resident = round(gov_body_cost / pop, 2)) |>
  arrange(short) |>
  print(n = 12)
