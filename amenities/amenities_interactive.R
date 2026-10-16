# Interactive amenities map for the Reed neighborhood (Portland, OR)

library(tidyverse)
library(sf)
library(osmextract)
library(leaflet)
library(crosstalk)
library(DT)
library(htmlwidgets)
library(htmltools)
library(RColorBrewer)

# Some OSM's polygon data is invalid. sf's s2 is too strict, so turn it off
sf_use_s2(FALSE)

# --- create map area ----------------------------------------------------------
# Bounding box vaguely around inner Portland to I-205 on the east
bb <- c(-122.72, 45.46, -122.55, 45.56)

# a shapefile that contains the outline of Reed
reed <- st_read("amenities/data/reed_boundary/reed_boundary_WGS.shp", quiet = TRUE) |>
  st_transform(4326)

# --- Pull amenities from OpenStreetMap -----------------------------------
# OSM is supposed to be accessible with Overpass API, but that kept giving 502/504 errors
# So instead, this reads from my local OSM extract (big download) and creates a cached rds

# my local file
extract_file <- "/Users/griffinj/Documents/GIS_files/osm_extracts/bbbike_Portland.osm.pbf"
# the cache it creates
cache_file <- "amenities/data/amenities_raw_inner_pdx.rds"
# the area to pull from (because raw is larger than my desired plot area)
study_area <- st_bbox(c(xmin = bb[1], ymin = bb[2], xmax = bb[3], ymax = bb[4]), crs = st_crs(4326))

# choose the amenities; there are more  but this is a curated list that I found fun/interesting
# if you want to see all types, remove this from the filtering and 
# then run unique(amenities$amenity)
included_amenities <- c(
  "bar", "biergarten", "cafe", "fast_food", "food_court", "ice_cream", "pub", "restaurant",
  "arts_centre", "casino", "cinema", "community_centre", "conference_centre",
  "events_venue", "exhibition_centre", "fountain", "gambling", "love_hotel", "music_venue",
  "nightclub", "planetarium", "public_bookcase", "social_centre", "stage", "stripclub",
  "studio", "swingerclub", "theatre", "veterinary", "dentist", "baby_hatch", "library",
  "bicycle_parking", "bicycle_repair_station", "bicycle_rental", "courthouse", "fire_station", 
  "police", "post_box", "post_depot", "post_office", "prison", "ranger_station", "townhall",
  "bbq", "dog_toilet", "drinking_water", "toilets", "recycling", "animal_shelter", "clock", 
  "crematorium", "grave_yard", "public_bath", "refugee_site", "hydrant"
)

# if the cache hasn't been created this will run and pull the things I want
# I wanted to add dispensaries which for some reason was in "shops" instead of amenities
# so that's a separate pull

if (file.exists(cache_file)) {
  amenities <- readRDS(cache_file)
} else {

  # Amenities are points, but some are tagged on building footprints, so
  # polygons are reduced to centroids
  read_layer <- function(layer) {
    oe_read(extract_file, layer = layer, extra_tags = c("amenity", "shop"), quiet = TRUE) |>
      st_transform(4326) |>
      select(name, amenity, shop)
  }

  pts <- bind_rows(
    read_layer("points"),
    read_layer("multipolygons") |> st_centroid()
  ) |>
    st_crop(study_area)

  # get dispensaries by searching for "cannabis" shops
  dispensaries <- pts |>
    filter(shop == "cannabis") |>
    transmute(name, amenity = "dispensary")

  # filter for just the amenities I picked
  amenities <- pts |>
    filter(amenity %in% included_amenities) |>
    transmute(name, amenity)

  #combine
  amenities <- bind_rows(amenities, dispensaries)

  # create cache
  dir.create(dirname(cache_file), showWarnings = FALSE, recursive = TRUE)
  saveRDS(amenities, cache_file)
}

# remove anything that doesn't have a name
named_amenities <- amenities |>
  filter(!is.na(name))

# --- Assemble everything that will be displayed in the widget --------------------------------------

# get distance from Reed
amenities <- amenities |>
  mutate(dist_miles = as.numeric(st_distance(geometry, st_union(reed))) / 1609.344)

# set coordinates chosen area
coords <- st_coordinates(named_amenities)

# get df with information that I want to show in the hover dialogue and the table 
amenities_df <- named_amenities |>
  st_drop_geometry() |>
  mutate(
    lon = coords[, "X"],
    lat = coords[, "Y"],
    type = str_to_sentence(str_replace_all(amenity, "_", " ")),
    location = sprintf("%.4f, %.4f", lat, lon),
    dist_miles = round(dist_miles, 2)
  ) |>
  select(name, type, location, dist_miles, lon, lat)

# this is a crosstalk thing so that multiple widgets (map and table) share data
shared <- SharedData$new(amenities_df)

# --- Make the Map ---------------------------------------------------------------

# color the amenities by type
n_types <- n_distinct(amenities_df$type)
pal <- colorFactor(colorRampPalette(RColorBrewer::brewer.pal(12, "Paired"))(n_types), domain = amenities_df$type)

# have the intial map be centered around Reed
reed_center <- unname(st_coordinates(st_centroid(st_union(reed)))[1, ])

# make the map with leaflet so it's interactive
map <- leaflet(shared, width = "100%") |>
  # provider tiles is what the background of the map is
  addProviderTiles("Esri.WorldGrayCanvas") |>
  # make the Reed boundary distinct
  addPolygons(data = reed, fillColor = "grey50", fillOpacity = 0.35, color = NA) |>
  # add the points
  addCircleMarkers(
    lng = ~lon, lat = ~lat,
    radius = 6, stroke = TRUE, color = "white", weight = 1,
    fillColor = ~pal(type), fillOpacity = 0.9,
    label = ~lapply(paste0(htmlEscape(name), "<br/>", htmlEscape(type)), HTML)
  ) |>
  # center initial map
  setView(lng = reed_center[1], lat = reed_center[2], zoom = 14)

# --- Create Data Table Below map ---------------------------------------------------------------
# show the name of the thing, the type, distance from Reed, and location 
# (just lat and long, address is likely possible, but I got lazy)
table <- datatable(
  shared,
  colnames = c("Name" = "name", "Type" = "type", "Location (lat, lon)" = "location", "Distance from Reed (mi)" = "dist_miles"),
  rownames = FALSE,
  options = list(
    columnDefs = list(list(targets = c(4, 5), visible = FALSE)),
    order = list(list(3, "asc"))
  )
)

# --- Legend -------------------------------------------------------------
# uses leaflets legend type, but I wanted to move it from the side 
# to be in columns above the map and that took a little finagling 

type_levels <- sort(unique(amenities_df$type))
type_colors <- setNames(pal(type_levels), type_levels)

legend_items <- lapply(type_levels, function(lvl) {
  tags$div(
    class = "static-legend-item",
    tags$span(class = "static-legend-swatch", style = paste0("background-color:", type_colors[[lvl]], ";")),
    lvl
  )
})

legend_box <- tags$div(
  class = "static-legend",
  tags$style(HTML("
    .static-legend { column-count: 4; column-gap: 16px; margin-bottom: 10px; font-size: 13px; }
    .static-legend-item { display: flex; align-items: center; gap: 6px; break-inside: avoid; margin-bottom: 4px; }
    .static-legend-swatch { width: 14px; height: 14px; flex-shrink: 0; border-radius: 2px; }
  ")),
  legend_items
)

# --- Layout and save -------------------------------------------------------
# crosstalk package enables bootstrap styling 
# needed widget to embed into wordpress as an iframe 


# Reports this page's real height to whatever window embeds it (e.g. a
# WordPress iframe), so the embed can resize itself instead of guessing a
# fixed height and getting an internal scrollbar. Fires on load and on any
# later size change (opening the type picker, changing DT's page length,
# paginating, etc). The embedding page has to listen for this - see
# amenities/README.md.
resize_reporter <- tags$script(HTML("
  (function() {
    function sendHeight() {
      window.parent.postMessage(
        { type: 'amenities-map-resize', height: document.documentElement.scrollHeight },
        '*'
      );
    }
    window.addEventListener('load', sendHeight);
    new ResizeObserver(sendHeight).observe(document.body);
  })();
"))

widget <- tagList(
  bscols(widths = 12, filter_select("type", "Click in box to display specific amenities", shared, ~type, multiple = TRUE)),
  bscols(widths = 12, legend_box),
  bscols(widths = 12, map),
  bscols(widths = 12, table),
  resize_reporter
)

# this is technically a couple widgets because of the tagList, so can't just use
# saveWidget(), so render through a throwaway .Rmd instead -
# rmarkdown shells out to pandoc, so it needs to be installed
Sys.setenv(RSTUDIO_PANDOC = path.expand("~/.local/bin"))

# this just compiles everything as html with a title and whatnot
rmd_path <- tempfile(fileext = ".Rmd")
writeLines(c(
  "---",
  "title: Ice Cream & Grave Yards - 'Amenities' Near Reed",
  "output:",
  "  html_document:",
  "    self_contained: true",
  "---",
  "",
  "```{r echo=FALSE, warning=FALSE, message=FALSE}",
  "widget",
  "```"
), rmd_path)

# save it to a file
rmarkdown::render(
  rmd_path,
  output_file = "amenities_interactive.html",
  output_dir = "amenities",
  envir = environment(),
  quiet = TRUE
)
