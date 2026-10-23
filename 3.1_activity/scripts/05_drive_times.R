# scripts/05_drive_times.R
# Makes data/police_hq_drive_times.csv: the drive time from TCNJ to each nearby police
# headquarters, which 06_police_salary.R uses to pick the towns within 20 minutes.
# The CSV is already in data/, so you only need to run this to see how it was made, or to
# change the starting point (say, to a different job than TCNJ).
#
# Needs an internet connection. It asks two free public services for answers:
#   1) the Census Bureau's geocoder turns each street address into latitude and longitude
#   2) OSRM, a routing program that runs on OpenStreetMap's road map, returns the drive time
# Neither needs an account or a key. Please run it a few times, not hundreds: they are shared
# servers.
#
# New in this script (not in the Module 2 workbook):
#   jsonlite::fromJSON()  reads the answer a website sends back. jsonlite installs with the
#                         tidyverse; the :: works like janitor::clean_names() in 2.6.
#   URLencode()           turns spaces and commas into characters a web address can carry.
#   paste0()              is paste() with sep = "".
#   paste(collapse = ";") glues a whole column into one piece of text.
#   [1, -1]               means "row 1, every column except the first."


# Settings, Packages, and Load the Data ---------------------------------------------------

library(tidyverse)
library(readxl)

# Where the drive starts: TCNJ (Wikipedia gives 40.2712 N, 74.7829 W). West is negative!
start_lat <- 40.2712
start_lon <- -74.7829

# col_types = "text" keeps muni_code as text (0304, not 304); the two lat/lon columns are
# fixed right after
hq <- read_excel(
  "data/police_hq_addresses.xlsx",
  sheet = "addresses",
  col_types = "text"
) |>
  mutate(
    lat_osm = as.numeric(lat_osm),
    lon_osm = as.numeric(lon_osm)
  )

# One row is one police department. Expect 19 rows and 10 columns.
dim(hq)
names(hq)
summary(hq)   # lat_osm and lon_osm: 17 NA's (filled in only where the Census can't find the address)

# Is muni_code a key? Should return zero rows.
hq |>
  count(muni_code) |>
  filter(n > 1)


# Step 1: Address to Latitude and Longitude (Census Geocoder) -------------------------------

# This function sends one address to the Census geocoder and hands back a one-row table.
# Try it on one address first (the tribble() rule: test on something small enough to check):
#   geocode_census("2 Jake Garzio Drive, Ewing, NJ 08628")
geocode_census <- function(address) {
  url <- paste0(
    "https://geocoding.geo.census.gov/geocoder/locations/onelineaddress",
    "?benchmark=Public_AR_Current&format=json",
    "&address=", URLencode(address, reserved = TRUE)
  )
  matches <- jsonlite::fromJSON(url)$result$addressMatches

  # No match comes back as an empty list. Record NA instead of stopping.
  if (length(matches) == 0) {
    return(tibble(
      geocode_address = address,
      census_match    = NA_character_,
      census_lat      = NA_real_,
      census_lon      = NA_real_
    ))
  }

  # Otherwise keep the first (best) match. The Census calls longitude x and latitude y.
  tibble(
    geocode_address = address,
    census_match    = matches$matchedAddress[1],
    census_lat      = matches$coordinates$y[1],
    census_lon      = matches$coordinates$x[1]
  )
}

# Same pattern as 01_import.R: run the function once per address, then stack the rows
census <- map(hq$geocode_address, geocode_census) |>
  list_rbind()

# Before the merge, what I expect:
# 1) Rows: 19 in, 19 out (hq is the left table, and geocode_address is unique in both).
# 2) Drops: none, but 2 rows should get NA from the Census: South Brunswick (540 Ridge Road) and
#    Mansfield (3135 Route 206). The Census address list doesn't have them.
# 3) Why: the Census only knows addresses in its own files. See notes in the spreadsheet.
census |>
  count(geocode_address) |>
  filter(n > 1)

hq_geo <- hq |>
  left_join(census, join_by(geocode_address)) |>
  mutate(
    lat      = coalesce(census_lat, lat_osm),   # use the Census point; if it's NA, use OpenStreetMap's
    lon      = coalesce(census_lon, lon_osm),
    geocoder = if_else(is.na(census_lat), "OpenStreetMap (Nominatim)", "Census")
  )

dim(hq_geo)                  # expect 19 rows
count(hq_geo, geocoder)      # expect Census 17, OpenStreetMap (Nominatim) 2
hq_geo |>
  filter(is.na(lat))         # expect zero rows: every department has a point now

# Look at what the Census matched. Does each matched address look like the one you sent?
hq_geo |>
  select(municipality, geocode_address, census_match)


# Step 2: Drive Times (OSRM on OpenStreetMap) ---------------------------------------------

# OSRM's "table" service takes one list of points and returns the drive time between them.
# Point 1 is TCNJ; points 2 through 20 are the departments, in the same order as hq_geo.
# sources=0 asks only for the times FROM point 1 (OSRM counts from 0), so we get one row back.
# Careful: OSRM wants longitude FIRST, then latitude. Flip them and you'll be routed to Antarctica!
points <- paste(
  c(start_lon, hq_geo$lon),
  c(start_lat, hq_geo$lat),
  sep = ",",
  collapse = ";"
)

osrm_url <- paste0(
  "https://router.project-osrm.org/table/v1/driving/", points,
  "?sources=0&annotations=duration,distance"
)
osrm_url   # paste this into a browser to see the raw answer yourself

osrm <- jsonlite::fromJSON(osrm_url)
osrm$code   # should say "Ok"

# durations (seconds) and distances (meters) come back as a table with 1 row and 20 columns.
# Column 1 is TCNJ to itself (0), so drop it.
drive_times <- hq_geo |>
  mutate(
    drive_sec   = osrm$durations[1, -1],
    drive_min   = drive_sec / 60,
    drive_miles = osrm$distances[1, -1] / 1609.344
  ) |>
  select(muni_code, municipality, county, department, hq_address, geocoder, lat, lon,
         drive_sec, drive_min, drive_miles) |>
  arrange(drive_sec)

# Check: about 4 to 5 minutes and 2 miles for Ewing? Nothing negative or NA?
drive_times |>
  select(municipality, drive_min, drive_miles)
summary(drive_times$drive_min)

# These times assume no traffic: OSRM uses the posted speed limit on every road. Rush hour will
# be slower. Google Maps' "typically" range includes traffic, so expect it to run higher.

write_csv(drive_times, "data/police_hq_drive_times.csv")
