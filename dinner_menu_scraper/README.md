# What's for Dinner?

Pulls Commons' dinner menu (Classics and SimplyOASIS stations) for the
Spring 2026 semester, tags each dish with its main ingredient, and plots
how often each one showed up.

## Files

- `scrape_meals.R` — scraper that pulls dinner menu for every date from
  2026-01-26 to 2026-05-14, set to keep only Classics and SimplyOASIS
  stations, but dates and stations can be changed. Writes
  `data/dinner_jan26_may14.csv`.
- `menu_analysis.R` — reads the scraped CSV, classifies each dish by main
  ingredient and by Meat/Veggie/Mixed. Builds `ingredient_plot` images.
- `data/dinner_jan26_may14.csv` — the scraped data (one row per dish per
  date served).
- `ingredient_plot.svg` — the final plot, vector format for print layout.
- `robust_scrape_dinner_menu.R` — Claude made this one based off my simple
  one. Theoretically it is a more general-purpose version of the scraper
  with more safety checks. I haven't gone through it.

## Workflow

Required packages: `httr`, `jsonlite`, `stringr`, `readr`, `tidyverse`,
`ggpattern`, and `svglite`

Run `scrape_meals.R` then run `menu_analysis.R`

Makes plot and prints a summary table of dish counts by main ingredient

## Notes on the ingredient classification

- Dishes are matched by keywords in their `item_name` (not the fuller
  `description`)
- Ingredients are labeled in a fixed order so that "Ancho Braised Beef with
  Cowboy Beans" lands in beef rather than beans
- Brand-name fake meat (Beyond, Gardein "Chik'n", Impossible) are in "Meat
  Substitute" category
- Some dishes aren't actually dinner entrées, like ice cream, so they are
  removed
