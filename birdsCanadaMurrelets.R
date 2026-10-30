# Marbled Murrelets - NatureCounts
#
# Author: Stephen Finnis
# Date: October 30, 2026
#
# PURPOSE
# Download Marbled Murrelet observation records from NatureCounts for use
# in the SeaSketch layer "Marbled Murrelets - NatureCounts".
#
# REQUIREMENTS
# A NatureCounts account is required to access and download the data.
# If you don't already have an account, follow the instructions here:
# https://learn.birdscanada.org/additional-resources/naturecounts/accessdata/creating-naturecounts-account/
#
# DATA DOWNLOAD AND OUTPUT
# This script uses the NatureCounts R package to download available
# Marbled Murrelet records for British Columbia and saves them as a
# GeoPackage (.gpkg).
#
# The map created in this script is for visualization and checking the
# downloaded records only. It is not uploaded to SeaSketch.
#
# CONNECTING TO SEASKETCH
# The GeoPackage output is uploaded separately to ArcGIS Online (AGOL).
# The AGOL layer is then connected to SeaSketch, where it is displayed
# as the "Marbled Murrelets - NatureCounts" layer.
#
# SeaSketch: https://www.seasketch.org/mpatt/


# Install packages if needed
install.packages(
  "naturecounts",
  repos = c(
    birdscanada = "https://birdscanada.r-universe.dev",
    CRAN = "https://cloud.r-project.org"
  )
)

install.packages(c(
  "sf",
  "dplyr",
  "ggplot2",
  "rnaturalearth"
))

# Load packages
library(naturecounts)
library(sf)
library(dplyr)
library(ggplot2)
library(rnaturalearth)

# NatureCounts username
# Enter your username locally. Do not commit personal account details to GitHub.
username <- Sys.getenv("NATURECOUNTS_USERNAME")

# Find Marbled Murrelet species ID
murrelet_species <- search_species("Marbled Murrelet")
murrelet_id <- murrelet_species$species_id[1]

print(murrelet_species)
print(murrelet_id)

# Check available Marbled Murrelet datasets and access levels in BC
murrelet_datasets <- nc_count(
  species = murrelet_id,
  region = list(statprov = "BC"),
  show = "all",
  username = username
)

print(murrelet_datasets)

# Download available Marbled Murrelet records from British Columbia
murrelets <- nc_data_dl(
  species = murrelet_id,
  region = list(statprov = "BC"),
  fields_set = "extended",
  username = username,
  info = "Marbled Murrelet records in British Columbia"
)

# Check downloaded data
print(paste("Number of records downloaded:", nrow(murrelets)))
print(names(murrelets))

# Convert records to spatial points
murrelets_sf <- murrelets %>%
  filter(
    !is.na(longitude),
    !is.na(latitude)
  ) %>%
  st_as_sf(
    coords = c("longitude", "latitude"),
    crs = 4326
  )

# Get British Columbia boundary for visualization
bc <- ne_states(
  country = "Canada",
  returnclass = "sf"
) %>%
  filter(name_en == "British Columbia")

# Map downloaded records for visualization
ggplot() +
  geom_sf(
    data = bc,
    fill = "grey95",
    colour = "grey50",
    linewidth = 0.3
  ) +
  geom_sf(
    data = murrelets_sf,
    size = 0.8,
    alpha = 0.4
  ) +
  coord_sf(
    xlim = c(-140, -123),
    ylim = c(48, 56)
  ) +
  theme_minimal() +
  labs(
    title = "Marbled Murrelet Records in British Columbia",
    subtitle = "NatureCounts",
    x = NULL,
    y = NULL
  )

# Save spatial data as a GeoPackage for upload to AGOL
st_write(
  murrelets_sf,
  "Marbled_Murrelet_NatureCounts_BC.gpkg",
  layer = "Marbled_Murrelet",
  delete_dsn = TRUE
)