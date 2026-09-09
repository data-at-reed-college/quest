# quest

Data and code behind the visualizations in the *Quest*'s weekly data column.

Each article gets its own folder here, named for the topic. A folder holds
everything needed to reproduce that week's chart from scratch: the script(s)
that pull the raw data, the script that cleans/analyzes it, the resulting
data files, the final chart, and a `README.md` with step-by-step
instructions for rerunning the whole thing.

## Folders

- [`dinner_menu_scraper/`](dinner_menu_scraper/) — What's actually being
  served at Commons dinner (SimplyOASIS and Classics stations), broken down
  by main ingredient and meat vs. veggie.

## Conventions

- Scripts are R unless a folder says otherwise.
- Raw/scraped data lives in each folder's `data/` subfolder as CSV.
- Each folder's own README has the exact commands to reproduce its data
  pull, analysis, and chart from a clean checkout.
