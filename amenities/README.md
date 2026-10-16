# Amenities near Reed

What's around the Reed neighborhood (and, for the interactive version, inner
Portland out to I-205): restaurants, bars, dispensaries, and dozens of other
OpenStreetMap amenity types, plotted relative to campus.

## Files

- `amenities_map.R` — the static version used for the print graphic.
  Produces `amenities_map.png` (the map) and `fun_table.png` (a summary
  table of a few "fun" amenity types near campus).
- `amenities_interactive.R` — the interactive web version. Produces
  `amenities_interactive.html`, a single self-contained file meant to be
  embedded via `<iframe>`. Lets a reader pick amenity types from a search
  box, see a colored legend, browse the map (centered on Reed, pannable out
  to inner Portland), and see a linked table of what's currently shown.
- `data/amenities_raw_inner_pdx.rds` — cached amenity pull for the
  interactive map (see below).
- `data/reed_boundary/` — the Reed campus boundary shapefile, used by both
  scripts to shade campus on the map and compute distance-from-campus.

Both scripts should be run from the `Quest/` repo root.

## Reproducing

```r
source("amenities/amenities_map.R")
source("amenities/amenities_interactive.R")
```

### Dependencies

- `amenities_map.R` pulls live from the Overpass API (OpenStreetMap).
- `amenities_interactive.R` reads from a local OSM extract (bbbike's
  "Portland" metro-area file, downloaded once via
  `osmextract::oe_download()`) rather than live Overpass, which turned out
  to be unreliable. That extract (~70MB) is kept outside the repo and is
  **not** committed — it's general-purpose data, reusable for any
  Portland-area project, not just this one.
- Because `data/amenities_raw_inner_pdx.rds` is committed, you don't
  actually need that extract unless you're changing the amenity list or
  the bounding box (`included_amenities` / `bb` in
  `amenities_interactive.R`). Delete the cache file to force a rebuild —
  that's when the extract dependency kicks in.

### Also needs

- `pandoc`, for the self-contained HTML build. If `rmarkdown` can't find a
  usable pandoc install, see `pandoc::pandoc_install()`.

## Embedding

Published via GitHub Pages at
`https://data-at-reed-college.github.io/quest/amenities/amenities_interactive.html`.

The page auto-reports its height to its parent window via `postMessage` (an
iframe can't otherwise know its own content's height, and a fixed guess
breaks whenever the content changes size — opening the type picker,
switching the table's page length, paginating, etc.). The embedding page
needs a small listener alongside the iframe to use it:

```html
<iframe
  id="amenities-map-iframe"
  src="https://data-at-reed-college.github.io/quest/amenities/amenities_interactive.html"
  width="100%"
  height="800"
  style="border:none;"
  loading="lazy"
  title="Amenities near Reed — interactive map">
</iframe>
<script>
  window.addEventListener('message', function(event) {
    if (event.data && event.data.type === 'amenities-map-resize') {
      var iframe = document.getElementById('amenities-map-iframe');
      if (iframe) iframe.style.height = event.data.height + 'px';
    }
  });
</script>
```
