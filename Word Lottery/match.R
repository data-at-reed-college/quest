library(tidyverse)
library(googlesheets4) # this connects to google sheets
library(tidytext) # this helps parse text
library(httr2) # this helps access websites

sheet_url <- "https://docs.google.com/spreadsheets/d/10zIfhsiL6iMBRcLe7-cR-aGjMOjSEf49UUPJ3VuFNlo"

word_list <- read_sheet(sheet_url, sheet = "full_word_list")
match_list <- read_sheet(sheet_url, sheet = "matched_words")

# words not already in match_list, renamed to match its columns
new_words <- word_list |>
  anti_join(match_list, by = c("word" = "submit")) |>
  select(email = `Email Address`, submit = word)

match_list <- bind_rows(match_list, new_words)

# give each row without a match a random word from the other unmatched rows
set.seed(6) 
unmatched <- which(is.na(match_list$match))

repeat {
  picks <- sample(unmatched) # each word gets used once

  # reshuffle if anyone gets their own word
  same_person <- str_to_lower(match_list$email[unmatched]) == str_to_lower(match_list$email[picks])
  same_word <- str_to_lower(match_list$submit[unmatched]) == str_to_lower(match_list$submit[picks])
  if (!any(same_person | same_word)) break
}

match_list$match[unmatched] <- match_list$submit[picks]

# save to the google sheet (this replaces what's in the matched_words tab)
sheet_write(match_list, ss = sheet_url, sheet = "matched_words")
