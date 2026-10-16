# Interactive amenities map for the Reed neighborhood (Portland, OR)
# Run from the Quest/ repo root (paths below are relative to it).
# Produces a single self-contained HTML file meant to be embedded via <iframe>.

library(tidyverse)
library(sf)
library(osmextract)
library(leaflet)
library(crosstalk)
library(DT)
library(htmlwidgets)
library(htmltools)
library(RColorBrewer)

# Some OSM polygon data has invalid/unclosed rings. sf's s2 (spherical)
# backend is strict about this and errors on st_crop(); GEOS (planar) just
# handles it.
sf_use_s2(FALSE)

# --- Study area ----------------------------------------------------------
# Bounding box covering inner Portland out to I-205 (order: xmin, ymin,
# xmax, ymax in lon/lat).

bb <- c(-122.72, 45.46, -122.55, 45.56)

reed <- st_read("amenities/data/reed_boundary/reed_boundary_WGS.shp", quiet = TRUE) |>
  st_transform(4326)

# --- Pull amenities from OpenStreetMap -----------------------------------
# Reads from a local OSM extract (bbbike's "Portland" metro-area file,
# downloaded once via osmextract::oe_download() into
# ~/Documents/GIS_files/osm_extracts/) rather than the live Overpass API,
# which is unreliable. Cached locally after the first build; delete the
# cache file (not the extract) to rebuild after changing
# `included_amenities` or `bb`.
#
# The amenity subset below (picked from the OSM wiki's amenity groups)
# keeps the map focused on things worth checking off, instead of every
# bench and waste basket.

included_amenities <- c(
  # Sustenance
  "bar", "biergarten", "cafe", "fast_food", "food_court", "ice_cream", "pub", "restaurant",
  # Entertainment, Arts & Culture
  "arts_centre", "brothel", "casino", "cinema", "community_centre", "conference_centre",
  "events_venue", "exhibition_centre", "fountain", "gambling", "love_hotel", "music_venue",
  "nightclub", "planetarium", "public_bookcase", "social_centre", "stage", "stripclub",
  "studio", "swingerclub", "theatre",
  # Healthcare (subset)
  "veterinary", "dentist", "baby_hatch",
  # Education (subset)
  "library",
  # Transportation (subset)
  "bicycle_parking", "bicycle_repair_station", "bicycle_rental",
  # Public Service
  "courthouse", "fire_station", "police", "post_box", "post_depot", "post_office",
  "prison", "ranger_station", "townhall",
  # Facilities (subset)
  "bbq", "dog_toilet", "drinking_water", "toilets",
  # Waste Management (subset)
  "recycling",
  # Other
  "animal_shelter", "clock", "crematorium", "grave_yard", "public_bath", "refugee_site", "hydrant"
)

extract_file <- "/Users/griffinj/Documents/GIS_files/osm_extracts/bbbike_Portland.osm.pbf"
cache_file <- "amenities/data/amenities_raw_inner_pdx.rds"
study_area <- st_bbox(c(xmin = bb[1], ymin = bb[2], xmax = bb[3], ymax = bb[4]), crs = st_crs(4326))

if (file.exists(cache_file)) {
  amenities <- readRDS(cache_file)
} else {
  # Amenities are points, but some are tagged on building footprints, so
  # polygons (the "multipolygons" layer) are reduced to centroids.
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

  # Dispensaries are tagged as shops, not amenities.
  dispensaries <- pts |>
    filter(shop == "cannabis") |>
    transmute(name, amenity = "dispensary")

  amenities <- pts |>
    filter(amenity %in% included_amenities) |>
    transmute(name, amenity)

  amenities <- bind_rows(amenities, dispensaries)

  dir.create(dirname(cache_file), showWarnings = FALSE, recursive = TRUE)
  saveRDS(amenities, cache_file)
}

amenities <- amenities |>
  mutate(dist_miles = as.numeric(st_distance(geometry, st_union(reed))) / 1609.344)

# Unnamed places aren't useful on an interactive map (nothing to hover/show
# in the table).
named_amenities <- amenities |>
  filter(!is.na(name))

# --- Build the data behind the widget --------------------------------------

coords <- st_coordinates(named_amenities)

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

shared <- SharedData$new(amenities_df)

# --- Map ---------------------------------------------------------------

n_types <- n_distinct(amenities_df$type)
pal <- colorFactor(colorRampPalette(RColorBrewer::brewer.pal(12, "Paired"))(n_types), domain = amenities_df$type)

# Open centered on Reed rather than on the bbox's own (off-center) midpoint.
reed_center <- unname(st_coordinates(st_centroid(st_union(reed)))[1, ])

map <- leaflet(shared, width = "100%") |>
  addProviderTiles("Esri.WorldGrayCanvas") |>
  addPolygons(data = reed, fillColor = "grey50", fillOpacity = 0.35, color = NA) |>
  addCircleMarkers(
    lng = ~lon, lat = ~lat,
    radius = 6, stroke = TRUE, color = "white", weight = 1,
    fillColor = ~pal(type), fillOpacity = 0.9,
    label = ~lapply(paste0(htmlEscape(name), "<br/>", htmlEscape(type)), HTML)
  ) |>
  setView(lng = reed_center[1], lat = reed_center[2], zoom = 14)

# --- Table ---------------------------------------------------------------
# lon/lat stay in the shared data (leaflet needs them) but are hidden here;
# columnDefs targets are 0-based column indexes (rownames are off).

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
# A plain, non-interactive color key (square swatches, like leaflet's own
# addLegend()), laid out in columns. Filtering is the separate type picker
# below.

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
# Each piece is its own full-width (12-column) row; bscols() lays out the
# contents passed in a *single* call side by side, so stacking rows means
# calling it once per row.

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

# saveWidget() only handles a single htmlwidget, and this layout is a
# tagList of several, so render through a throwaway .Rmd instead -
# rmarkdown's self_contained handling understands htmlwidget/crosstalk
# dependencies correctly. It shells out to pandoc; the R-managed pandoc
# install lives under a path with a space in it ("Application Support"),
# which breaks that call, so point it at a space-free symlink instead
# (~/.local/bin/pandoc).
Sys.setenv(RSTUDIO_PANDOC = path.expand("~/.local/bin"))

rmd_path <- tempfile(fileext = ".Rmd")
writeLines(c(
  "---",
  "title: Interesting 'Amenities' Near Reed",
  "output:",
  "  html_document:",
  "    self_contained: true",
  "---",
  "",
  "```{r echo=FALSE, warning=FALSE, message=FALSE}",
  "widget",
  "```"
), rmd_path)

rmarkdown::render(
  rmd_path,
  output_file = "amenities_interactive.html",
  output_dir = "amenities",
  envir = environment(),
  quiet = TRUE
)
