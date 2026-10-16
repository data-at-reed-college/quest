# amenities around the Reed neighborhood (Portland, OR)
# Run from the Quest/ repo root (paths below are relative to it).

library(tidyverse)
library(sf)
library(osmdata)
library(gt)

# --- Study area ----------------------------------------------------------
# Rough bounding box around Reed College (Reed / Eastmoreland / Woodstock edge).
# Order for osmdata is (xmin, ymin, xmax, ymax) in lon/lat.

bb <- c(-122.655, 45.468, -122.602, 45.498)

# Reed campus boundary (4 parcels), used to shade the campus on the map.
reed <- st_read("amenities/data/reed_boundary/reed_boundary_WGS.shp", quiet = TRUE) |>
  st_transform(4326)

# The default Overpass server is often overloaded; use a mirror.
set_overpass_url("https://overpass-api.de/api/interpreter")

# --- Pull amenities from OpenStreetMap -----------------------------------
# Source: OpenStreetMap contributors via the Overpass API (osmdata package).
# Amenities are points, but some are tagged on building footprints, so we
# keep the point and polygon layers and reduce polygons to their centroids.

# Points, plus polygons (buildings) reduced to their centroids.
as_points <- function(osm) {
  polygons <- if (is.null(osm$osm_polygons)) NULL else st_centroid(osm$osm_polygons)
  bind_rows(osm$osm_points, polygons)
}

amenities_osm <- opq(bbox = bb) |>
  add_osm_feature(key = "amenity") |>
  osmdata_sf()

# # Dispensaries are tagged as shops, not amenities, so they need their own query.
dispensaries_osm <- opq(bbox = bb) |>
  add_osm_feature(key = "shop", value = "cannabis") |>
  osmdata_sf()

amenities <- as_points(amenities_osm) |>
  filter(!is.na(amenity)) |>
  transmute(name, amenity)

dispensaries <- as_points(dispensaries_osm) |>
  filter(shop == "cannabis") |>
  transmute(name, amenity = "dispensary")

amenities <- bind_rows(amenities, dispensaries) |>
  st_transform(4326)

# --- Street network for the basemap --------------------------------------

streets_osm <- opq(bbox = bb) |>
  add_osm_feature(key = "highway", value = c("motorway", "trunk", "primary", "secondary", "tertiary", "residential")) |>
  osmdata_sf()
streets <- streets_osm$osm_lines

# --- fun amenities --------------------------------------
fun <- c("pub", "restaurant", "bar", "cafe", "ice_cream", "cinema", "stripclub", "swingerclub", "dispensary")

# Distance from every amenity to the nearest edge of campus.
amenities <- amenities |>
  mutate(dist_miles = as.numeric(st_distance(geometry, st_union(reed))) / 1609.344)

fun_stuff <- amenities |>
  filter(amenity %in% fun)

# The table covers everything in fun_stuff (the full `fun` list).
fun_sum <- fun_stuff |>
  st_drop_geometry() |>
  group_by(amenity) |>
  summarize(total = n(), avg_dist_miles = mean(dist_miles), sd_dist_miles = sd(dist_miles)) |>
  arrange(desc(total))

# Formatted table, distance as mean ± sd. sd is NA for types with only one place (shows the mean alone).
fun_table <- fun_sum |>
  mutate(amenity = str_to_sentence(str_replace_all(amenity, "_", " "))) |>
  gt() |>
  cols_label(
    amenity = "Type",
    total = "Count",
    avg_dist_miles = "Average Distance (miles)"
  ) |>
  fmt_number(columns = c(avg_dist_miles, sd_dist_miles), decimals = 2) |>
  cols_merge_uncert(col_val = avg_dist_miles, col_uncert = sd_dist_miles) |>  # mean ± sd
  sub_missing(missing_text = "—") |>
  tab_header(
    title = "Fun 'Amenities' Near Reed",
    subtitle = "Distance from the edge of campus"
  ) |>
  tab_source_note("Source: OpenStreetMap contributors") |>
  opt_row_striping() |>
  cols_width(
    amenity ~ px(170),
    total ~ px(110),
    avg_dist_miles ~ px(230)
  ) |>
  cols_align(align = "center", columns = c(total, avg_dist_miles)) |>
  tab_options(data_row.padding = px(10), column_labels.padding = px(10))



# --- Map -----------------------------------------------------------------
# Keep the most common amenity types and lump the rest into "other".

amenities_plot <- fun_stuff |>
  filter(amenity %in% c("dispensary", "ice_cream", "swingerclub", "pub")) |>
  mutate(type = fct_infreq(amenity))

# Spread out overlapping symbols. Places within `merge_dist` meters of each other
# form a cluster; a cluster's symbols are moved onto a small ring around its center
# and a line points back to each true location.
merge_dist <- 60  # meters
ring_base <- 75   # ring radius = ring_base + ring_step * cluster size, in meters
ring_step <- 15

pts_m <- amenities_plot |> st_transform(26910)  # UTM 10N, meters
xy <- st_coordinates(pts_m)

amenities_plot <- amenities_plot |>
  mutate(
    cluster = cutree(hclust(dist(xy), method = "complete"), h = merge_dist),
    x0 = xy[, 1], y0 = xy[, 2]
  ) |>
  st_drop_geometry() |>
  group_by(cluster) |>
  mutate(
    n = n(),
    angle = 2 * pi * (row_number() - 1) / n,
    radius = if_else(n > 1, ring_base + ring_step * n, 0),
    x1 = mean(x0) + radius * cos(angle),
    y1 = mean(y0) + radius * sin(angle)
  ) |>
  ungroup()

# Back to lon/lat for plotting.
to_lonlat <- function(x, y) {
  st_as_sf(tibble(x, y), coords = c("x", "y"), crs = 26910) |>
    st_transform(4326) |>
    st_coordinates()
}
true_ll <- to_lonlat(amenities_plot$x0, amenities_plot$y0)
shown_ll <- to_lonlat(amenities_plot$x1, amenities_plot$y1)

amenities_plot <- amenities_plot |>
  mutate(
    lon0 = true_ll[, 1], lat0 = true_ll[, 2],
    lon1 = shown_ll[, 1], lat1 = shown_ll[, 2]
  )
moved <- filter(amenities_plot, n > 1)

amenities_map <- ggplot() +
  geom_sf(data = reed, fill = "grey75", color = NA) +
  geom_sf(data = streets, color = "grey80", linewidth = 0.5) +
  geom_segment(data = moved, aes(x = lon0, y = lat0, xend = lon1, yend = lat1), color = "grey30", linewidth = 0.3) +
  geom_point(data = moved, aes(x = lon0, y = lat0), color = "grey30", size = 0.6) +  # true location
  geom_point(data = amenities_plot, aes(x = lon1, y = lat1, shape = type), color = "black", size = 3.5) +
  coord_sf(xlim = bb[c(1, 3)], ylim = bb[c(2, 4)], expand = FALSE) +
  scale_shape_manual(
    name = NULL,
    values = c(dispensary = 16, ice_cream = 17, swingerclub = 18, pub = 15),  # circle, triangle, diamond, square
    labels = c(dispensary = "Dispensary", ice_cream = "Ice cream shop", swingerclub = "Swingers club", pub = "Pub")
  ) +
  theme_void() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.caption = element_text(color = "grey40"),
    legend.text = element_text(size = 12),
    plot.margin = margin(10, 10, 10, 10)
  )


# Save files

ggsave("amenities/amenities_map.png", amenities_map, width = 8, height = 7, dpi = 300, bg = "white")
gtsave(fun_table, "amenities/fun_table.png")  # needs the webshot2 package

unique(amenities$amenity)
