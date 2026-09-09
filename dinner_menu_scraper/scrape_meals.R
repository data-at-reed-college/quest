
# load libraries
library(httr)
library(jsonlite)
library(stringr)
library(readr)

####  set selections for scraping
###############################

# get url for menu
cafe_url <- "https://reed.cafebonappetit.com/cafe/commons-cafe/%s/"

# select what meal (can be single value or vector)
daypart <- "Dinner"
# select station (can be single value or vector)
station_wanted <- c("SimplyOASIS", "Classics")
# select date range
dates <- seq(as.Date("2026-01-26"), as.Date("2026-05-14"), by = "day")


####  create functions to:
####  fetch webpage,  
####  extract the menu,
####  extract the correct part of day

# downloads one date's menu page as raw HTML
fetch_page <- function(d) {
  url <- sprintf(cafe_url, format(d, "%Y-%m-%d"))
  resp <- GET(url, timeout(30))
  stop_for_status(resp)
  content(resp, as = "text", encoding = "UTF-8")
}

# pulls the menu_items from the JavaScript and parses it as JSON
extract_menu_items <- function(html) {
  pattern <- regex("Bamco\\.menu_items\\s*=\\s*(\\{.*?\\});", dotall = TRUE)
  match <- str_match(html, pattern)
  fromJSON(match[1, 2], simplifyVector = FALSE)
}

# pulls the relevant daypart and returns as a named list
extract_dayparts <- function(html) {
  pattern <- regex(
    "Bamco\\.dayparts\\['(\\d+)'\\]\\s*=\\s*(\\{.*?\\});\\s*\\n\\s*\\}\\)\\(\\);",
    dotall = TRUE
  )
  matches <- str_match_all(html, pattern)[[1]]
  dayparts <- list()
  for (i in seq_len(nrow(matches))) {
    dayparts[[matches[i, 2]]] <- fromJSON(matches[i, 3], simplifyVector = FALSE)
  }
  dayparts
}


####  create function extract the actual meals
###############################

# helper function for pulling menu
# if a is NULL, return b; otherwise return a 
# (can't get combinable rows if NULL values are present)
`%||%` <- function(a, b) if (is.null(a)) b else a

# extracts meals based on previous parameters
get_meal_items <- function(d) {
  html <- fetch_page(d)
  menu_items <- extract_menu_items(html)
  dayparts <- extract_dayparts(html)

  # create empty list for output
  rows <- list()
  for (dp in dayparts) {
    # only do this for the correct meal time
    if (!(dp$label %in% daypart)) next

    # find every station that matches the station(s)_wanted
    # using Filter because it's lists not dataframes
    stations <- Filter(\(s) str_trim(str_remove_all(s$label, "<[^>]+>")) %in% station_wanted, dp$stations)

    # make sure there's something there to find
    if (length(stations) == 0) next

    # for every matching station, grab data for each of its items
    for (station in stations) {
      for (item_id in station$items) {
        # get the item's full list of things
        item <- menu_items[[item_id]]
        # make a dataframe out of the following
        rows[[length(rows) + 1]] <- data.frame(
          date = as.character(d),
          meal = dp$label,
          item_name = item$label,
          description = item$description %||% "", # put "" instead of NULL
          price = as.character(item$price %||% ""), # put "" instead of NULL
          dietary_tags = paste(unlist(item$cor_icon), collapse = ", ")
        )
      }
    }
  }
  # bind everything together
  do.call(rbind, rows)
}


####  actually pull the data
###############################

# create empty list for things to go in
rows <- list()
# get meal for each date
for (i in seq_along(dates)) {
  d <- dates[i]
  rows[[i]] <- get_meal_items(d) # this is the line that actually runs everything

  # prints each date just to show progress 
  cat(as.character(d), "\n")
  # small pause between requests (technically don't need if it's too slow)
  Sys.sleep(0.1)
}

all_meals <- do.call(rbind, rows)


####  write file
###############################

write_csv(all_meals, "data/dinner_jan26_may14.csv")

