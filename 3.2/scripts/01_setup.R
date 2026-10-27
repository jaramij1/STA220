# scripts/01_setup.R
# Setup check for Module 3.2. Run before class on October 27.


# Install the Two New Packages ---------------------------------------------------------------------

# patchwork puts two plots side by side in some of the figure scripts, and pdftools is what
# 02_import.R uses to read the tax-bill PDFs. These lines install each one only if you do not
# have it yet.
if (!requireNamespace("patchwork", quietly = TRUE)) install.packages("patchwork")

if (!requireNamespace("pdftools", quietly = TRUE)) install.packages("pdftools")

library(tidyverse)


# Load the Data ------------------------------------------------------------------------------------

# Every New Jersey town in the 2025 sheet of the UFB Database: one row per town.
nj_2025 <- read_csv(
  "data/nj_2025.csv",
  col_types = cols(muni_code = col_character())   # keep the code as text ("0101"), so it can be a key later
)

# One row is one NJ municipality's 2025 budget. Expect 564 rows and 18 columns.
dim(nj_2025)
names(nj_2025)
summary(nj_2025)


# The Check ----------------------------------------------------------------------------------------

# One bar for each kind of municipality. geom_bar() counts the rows for you.
ggplot(nj_2025, aes(x = type)) +
  geom_bar()
