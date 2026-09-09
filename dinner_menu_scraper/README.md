# What's for Dinner?

Pulls Reed Commons' dinner menu (Classics and SimplyOASIS stations) for the
Spring 2026 semester, tags each dish with its main ingredient, and charts
how often each one showed up.

## Files

- `scrape_meals.R` — the scraper actually used for this article. Fetches
  Commons' dinner menu for every date from 2026-01-26 to 2026-05-14,
  keeping only the Classics and SimplyOASIS stations, and writes
  `data/dinner_jan26_may14.csv`.
- `robust_scrape_dinner_menu.R` — a more general-purpose version of the
  scraper with a command-line interface (`--today`, `--backfill --start ...
  --end ...`, `--date ... --print-only`), any station(s)/daypart(s), and
  resume-safe backfilling. Useful if a future article needs a different
  date range or station.
- `menu_analysis.R` — reads the scraped CSV, classifies each dish by main
  ingredient (Chicken, Beef, Tofu, Mushroom, etc.) and by Meat/Veggie/Mixed,
  and builds `ingredient_plot.svg` / `ingredient_plot.png`.
- `data/dinner_jan26_may14.csv` — the scraped data (one row per dish per
  date served).
- `ingredient_plot.svg` — the final chart, vector format for print layout.

## Reproducing this from scratch

Requires R with the `httr`, `jsonlite`, `stringr`, `readr`, `tidyverse`,
`ggpattern`, and `svglite` packages installed.

```bash
# 1. Scrape the semester's dinner menu (takes a few minutes; polite delay
#    between requests). Only needs to be rerun if the date range changes.
Rscript scrape_meals.R

# 2. Classify dishes and regenerate the chart
Rscript menu_analysis.R
```

`menu_analysis.R` writes `ingredient_plot.svg` and prints a summary table
of dish counts by main ingredient to the console.

## Notes on the ingredient classification

- Dishes are matched by keywords in their `item_name` (not the fuller
  `description`), checked in a fixed order so a dish naming more than one
  ingredient (e.g. "Ancho Braised Beef with Cowboy Beans") lands in the
  first matching category rather than the last — meat beats legumes, which
  beats a catch-all "Other".
- Brand-name meat analogs (Beyond, Gardein "Chik'n", Impossible) are their
  own "Meat Substitute" category, not folded into the real meat they stand
  in for.
- A handful of dishes (desserts, a "gluten-free pasta available" menu note)
  aren't dinner entrées at all and are dropped rather than force-fit into a
  category.
