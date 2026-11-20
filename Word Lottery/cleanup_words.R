library(tidyverse)
library(googlesheets4) # this connects to google sheets
library(tidytext) # this helps parse text
library(httr2) # this helps access websites

raw_lottery <- read_sheet("https://docs.google.com/spreadsheets/d/18fq2a0W2yWcQb13OZfXjBCrjEVMW1BPPFQicDgsHeDQ")

# separate rows for each word, count letters, add flags
lottery <- raw_lottery |>
  separate_longer_delim(4, delim = regex("[,;]")) |>
  mutate(across(4, str_squish)) |>
  mutate(flag = replace_na(flag, "N")) |>
  mutate(n_letters = str_length(word)) 

print(lottery$word[lottery$flag == "Y"])

# add additional flags
add_flag <- c("zit", "Chimichanga", "fug", "daiquiri", "Zamboni", "cromulent", "Munchkin", "antidisestablishmentarianism")

lottery <- lottery |>
  mutate(flag = if_else(word %in% add_flag, "Y", flag))

print(lottery$word[lottery$flag == "Y"])

# function to pull from Miriam Webster API
# key is requested and then stored as "MW_KEY"
get_mw_date <- function(word, key = Sys.getenv("MW_KEY")) {
  resp <- request("https://www.dictionaryapi.com/api/v3/references/collegiate/json") |>
    req_url_path_append(URLencode(word)) |>
    req_url_query(key = key) |>
    req_perform() |>
    resp_body_json()
  Sys.sleep(0.2)
  # not-found words come back as a list of suggestion strings, so keep only real entries
  hit <- keep(resp, \(x) is.list(x) && !is.null(x$date) &&
                str_to_lower(str_remove(x$meta$id, ":.*")) == str_to_lower(word))
  if (length(hit) == 0) return(NA_character_)
  hit[[1]]$date |> str_remove_all("\\{[^}]*\\}") |> str_squish()
}

# use the function to pull the dates and add column to make numeric
word_dates <- lottery |>
  distinct(word) |>
  mutate(first_use = map_chr(word, possibly(get_mw_date, NA_character_))) |>
  mutate(
    first_use_year = if_else(
      str_detect(first_use, "century"),
      (parse_number(first_use) - 1) * 100 + 50,  # "14th century" -> 1350
      parse_number(first_use)                     # "circa 1450" -> 1450
    )
  )

# graph the word length with tiles
p_length <- lottery |>
  distinct(word, n_letters, flag) |>
  arrange(desc(flag == "Y")) |>
  group_by(n_letters) |>
  mutate(stack = row_number()) |>
  ungroup() |>
  ggplot(aes(x = n_letters, y = stack, fill = flag)) +
  geom_tile(width = 0.8, height = 0.8) +
  scale_fill_manual(values = c(N = "grey70", Y = "#000000"), guide = "none") +
  scale_x_continuous(breaks = 3:28, limits = c(2.5, 28.5),
                     expand = expansion(add = c(0.3, 0))) +
  scale_y_continuous(breaks = \(lim) {
    b <- scales::breaks_extended()(lim)
    b[b == round(b)]
  }) +
  labs(
    title = "Length of submitted words",
    subtitle = "Each square is one word. Jerk-words in black.",
    x = "Letters in word", y = "Number of words"
  ) +
  theme_minimal(base_family = "serif", base_size = 20) +
  theme(
    text = element_text(color = "black"),
    axis.text = element_text(color = "black", size = 14),
    axis.title = element_text(color = "black", size = 20),
    panel.grid = element_blank(),
    axis.line = element_line(color = "black"),
    axis.ticks.y = element_line(color = "black"),
    axis.text.x = element_text(size = 12),
    plot.title = element_text(face = "bold", size = 26, hjust = 0.5),
    plot.subtitle = element_text(size = 18, hjust = 0.5),
    plot.title.position = "plot"
  )


# graph the word dates
p_years <- word_dates |>
  filter(!is.na(first_use_year)) |>
  ggplot(aes(x = first_use_year)) +
  geom_histogram(binwidth = 50, boundary = 0, fill = "grey70", color = "white") +
  scale_x_continuous(breaks = scales::breaks_width(100)) +
  scale_y_continuous(breaks = scales::breaks_width(2),
                     expand = expansion(mult = c(0, 0.05))) +
  labs(
    title = "When Miriam-Webster says the words originated",
    x = "Year of first known use", y = "Number of words"
  ) +
  theme_minimal(base_family = "serif", base_size = 20) +
  theme(
    text = element_text(color = "black"),
    axis.text = element_text(color = "black", size = 18),
    axis.title = element_text(color = "black", size = 20),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.line.x = element_line(color = "black"),
    plot.title = element_text(face = "bold", size = 26, hjust = 0.5),
    plot.subtitle = element_text(size = 18, hjust = 0.5),
    plot.title.position = "plot"
  )

# save plots
ggsave("/Users/griffinj/Library/CloudStorage/GoogleDrive-griffinj@reed.edu/My Drive/my DataLab/Quest/Word Lottery/word_lengths.png", p_length, width = 8, height = 5, dpi = 300, bg = "white")
ggsave("/Users/griffinj/Library/CloudStorage/GoogleDrive-griffinj@reed.edu/My Drive/my DataLab/Quest/Word Lottery/word_origins.png", p_years, width = 8, height = 5, dpi = 300, bg = "white")


googlesheets4::gs4_auth()   # or googlesheets4::gs4_deauth() then re-auth; refreshes the expired login
googledrive::drive_auth()

ss <- googlesheets4::gs4_create("full_word_list_no_score", sheets = list(full_word_list = lottery))

folder <- googledrive::drive_get(
  path = "2026-2027 academic year/Thesis Word Lottery/",
  shared_drive = "DataLabbies"
)
googledrive::drive_mv(ss, path = folder)
