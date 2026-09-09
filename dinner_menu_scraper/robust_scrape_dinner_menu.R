#!/usr/bin/env Rscript
# Pulls the dinner menu from Reed College's Commons Café (Bon Appetit) site
# and appends it to a running CSV.
#
# The site (reed.cafebonappetit.com) renders each day's menu at a URL of the
# form /cafe/commons-cafe/YYYY-MM-DD/ and embeds the full menu for that date
# as inline JS objects (Bamco.dayparts / Bamco.menu_items) in the page
# source. We fetch the plain HTML and pull the JSON straight out of those
# objects rather than driving a browser.
#
# Requires: httr, jsonlite, stringr, readr
#
# Usage:
#   # Get today's dinner menu and append it to data/dinner_menu.csv
#   Rscript scrape_dinner_menu.R --today
#
#   # Backfill a date range (skips dates already present in the CSV)
#   Rscript scrape_dinner_menu.R --backfill --start 2025-09-08 --end 2026-09-08
#
#   # One-off: print a single date's dinner menu without saving
#   Rscript scrape_dinner_menu.R --date 2026-01-15 --print-only
#
# To build up history going forward, just run the --today command once a
# day (e.g. after dinner service). Each run appends only new dates, so
# re-running it is always safe.

# Packages -------------------------------------------------------------
suppressPackageStartupMessages({
  library(httr)
  library(jsonlite)
  library(stringr)
  library(readr)
})

# Site/scrape constants --------------------------------------------------
CAFE_URL <- "https://reed.cafebonappetit.com/cafe/commons-cafe/%s/"
USER_AGENT <- "Mozilla/5.0 (compatible; ReedDinnerMenuScraper/1.0)"
DAYPART_LABEL <- "Dinner"
# These stations list raw ingredients/condiments (e.g. "tomato", "ranch
# dressing") rather than prepared dishes, so they're excluded by default.
EXCLUDED_STATIONS <- c("Salad Bar", "Beverage Line")

# Default output path: data/dinner_menu.csv next to this script, regardless
# of the working directory it's run from.
script_dir <- dirname(sub("--file=", "", grep("--file=", commandArgs(trailingOnly = FALSE), value = TRUE)))
if (length(script_dir) == 0 || script_dir == "") script_dir <- "."
DEFAULT_OUT <- file.path(script_dir, "data", "dinner_menu.csv")

CSV_FIELDS <- c("date", "station", "item_name", "description", "price", "dietary_tags")

# Null-coalescing helper: falls back to b when a is NULL/empty (JSON fields
# that are missing come through this way).
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

# Downloads one date's menu page as raw HTML.
fetch_page <- function(d) {
  url <- sprintf(CAFE_URL, format(d, "%Y-%m-%d"))
  resp <- GET(url, add_headers(`User-Agent` = USER_AGENT), timeout(30))
  stop_for_status(resp)
  content(resp, as = "text", encoding = "UTF-8")
}

# Pulls the Bamco.menu_items JS object out of the page and parses it as JSON.
extract_menu_items <- function(html) {
  m <- str_match(html, regex("Bamco\\.menu_items\\s*=\\s*(\\{.*?\\});", dotall = TRUE))
  if (is.na(m[1, 2])) return(list())
  fromJSON(m[1, 2], simplifyVector = FALSE)
}

# Returns a named list: daypart_id -> daypart list, for every daypart on the page.
extract_dayparts <- function(html) {
  pattern <- regex(
    "Bamco\\.dayparts\\['(\\d+)'\\]\\s*=\\s*(\\{.*?\\});\\s*\\n\\s*\\}\\)\\(\\);",
    dotall = TRUE
  )
  matches <- str_match_all(html, pattern)[[1]]
  dayparts <- list()
  if (nrow(matches) == 0) return(dayparts)
  for (i in seq_len(nrow(matches))) {
    dayparts[[matches[i, 2]]] <- fromJSON(matches[i, 3], simplifyVector = FALSE)
  }
  dayparts
}

# Station labels sometimes come wrapped in HTML (e.g. "<strong>@Grill</strong>").
strip_tags <- function(x) str_trim(str_replace_all(x %||% "", "<[^>]+>", ""))

# Fetches one date's page and returns a data frame of dinner menu item rows
# (zero rows if no dinner was served that day).
get_dinner_items <- function(d) {
  html <- fetch_page(d)
  menu_items <- extract_menu_items(html)
  dayparts <- extract_dayparts(html)

  # Find the daypart by label rather than a hardcoded id, since daypart ids
  # vary by day.
  dinner <- NULL
  for (dp in dayparts) {
    if (identical(dp$label, DAYPART_LABEL)) {
      dinner <- dp
      break
    }
  }
  if (is.null(dinner)) return(CSV_FIELDS |> (\(f) setNames(rep(list(character(0)), length(f)), f))() |> as.data.frame(stringsAsFactors = FALSE))

  # Flatten station -> item_id -> item lookup into one row per dish.
  rows <- list()
  for (station in dinner$stations) {
    station_label <- strip_tags(station$label)
    if (station_label %in% EXCLUDED_STATIONS) next
    for (item_id in station$items) {
      item <- menu_items[[item_id]]
      if (is.null(item)) next
      cor_icon <- item$cor_icon
      tags <- if (is.list(cor_icon) && length(cor_icon) > 0) {
        paste(unlist(cor_icon, use.names = FALSE), collapse = ", ")
      } else {
        ""
      }
      rows[[length(rows) + 1]] <- data.frame(
        date = format(d, "%Y-%m-%d"),
        station = station_label,
        item_name = str_trim(item$label %||% ""),
        description = str_trim(item$description %||% ""),
        price = as.character(item$price %||% ""),
        dietary_tags = tags,
        stringsAsFactors = FALSE
      )
    }
  }
  if (length(rows) == 0) {
    return(setNames(data.frame(matrix(nrow = 0, ncol = length(CSV_FIELDS))), CSV_FIELDS))
  }
  do.call(rbind, rows)
}

# Reads back which dates are already in the output CSV, so reruns can skip them.
load_existing_dates <- function(csv_path) {
  if (!file.exists(csv_path)) return(character(0))
  df <- read_csv(csv_path, col_types = cols(.default = "c"), show_col_types = FALSE)
  unique(df$date)
}

# Appends rows to the CSV, writing a header only if the file is new.
append_rows <- function(csv_path, df) {
  dir.create(dirname(csv_path), recursive = TRUE, showWarnings = FALSE)
  file_exists <- file.exists(csv_path)
  write_csv(df, csv_path, append = file_exists, col_names = !file_exists)
}

# Minimal hand-rolled CLI flag parser (avoids an optparse dependency).
parse_args <- function(args) {
  opts <- list(
    today = FALSE, date = NULL, backfill = FALSE, start = NULL, end = NULL,
    out = DEFAULT_OUT, print_only = FALSE, delay = 0.5
  )
  i <- 1
  while (i <= length(args)) {
    a <- args[i]
    val <- function() { i <<- i + 1; args[i] }
    if (a == "--today") { opts$today <- TRUE }
    else if (a == "--date") { opts$date <- as.Date(val()) }
    else if (a == "--backfill") { opts$backfill <- TRUE }
    else if (a == "--start") { opts$start <- as.Date(val()) }
    else if (a == "--end") { opts$end <- as.Date(val()) }
    else if (a == "--out") { opts$out <- val() }
    else if (a == "--print-only") { opts$print_only <- TRUE }
    else if (a == "--delay") { opts$delay <- as.numeric(val()) }
    else if (a %in% c("-h", "--help")) {
      cat("Usage: Rscript scrape_dinner_menu.R [--today] [--date YYYY-MM-DD] [--backfill --start YYYY-MM-DD [--end YYYY-MM-DD]] [--out PATH] [--print-only] [--delay SECONDS]\n")
      quit(status = 0)
    } else {
      stop(sprintf("Unknown argument: %s", a))
    }
    i <- i + 1
  }
  opts
}

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  opts <- parse_args(args)

  if (!opts$today && is.null(opts$date) && !opts$backfill) {
    stop("Specify one of --today, --date, or --backfill.")
  }

  # Build the list of dates to fetch based on which mode was requested.
  if (!is.null(opts$date)) {
    dates <- opts$date
  } else if (opts$today) {
    dates <- Sys.Date()
  } else {
    if (is.null(opts$start)) stop("--backfill requires --start.")
    end <- opts$end %||% Sys.Date()
    dates <- seq(opts$start, end, by = "day")
  }

  existing <- if (opts$print_only) character(0) else load_existing_dates(opts$out)

  # Fetch each date, skipping ones already saved, and either print or append.
  total_rows <- 0
  for (i in seq_along(dates)) {
    d <- dates[i]
    d_str <- format(d, "%Y-%m-%d")
    if (d_str %in% existing) next

    rows <- tryCatch(
      get_dinner_items(d),
      error = function(e) {
        message(sprintf("%s: error (%s), skipping", d_str, conditionMessage(e)))
        NULL
      }
    )

    if (!is.null(rows)) {
      if (nrow(rows) == 0) {
        cat(sprintf("%s: no dinner menu found\n", d_str))
      } else {
        cat(sprintf("%s: %d dinner items\n", d_str, nrow(rows)))
        total_rows <- total_rows + nrow(rows)
        if (opts$print_only) {
          for (r in seq_len(nrow(rows))) {
            cat(sprintf("  [%s] %s (%s)\n", rows$station[r], rows$item_name[r], rows$dietary_tags[r]))
          }
        } else {
          append_rows(opts$out, rows)
        }
      }
    }

    if (length(dates) > 1 && i < length(dates)) Sys.sleep(opts$delay)
  }

  if (!opts$print_only) {
    cat(sprintf("\nDone. %d rows written to %s\n", total_rows, opts$out))
  }
}

main()
