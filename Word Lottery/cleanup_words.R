library(tidyverse)
library(googlesheets4)
library(tidytext)
library(httr2)

raw_lottery <- read_sheet("https://docs.google.com/spreadsheets/d/18fq2a0W2yWcQb13OZfXjBCrjEVMW1BPPFQicDgsHeDQ")

lottery <- raw_lottery |>
  separate_longer_delim(4, delim = regex("[,;]")) |>
  mutate(across(4, str_squish)) |>
  mutate(flag = replace_na(flag, "N")) |>
  mutate(n_letters = str_length(word)) 

print(lottery$word[lottery$flag == "Y"])

add_flag <- c("zit", "Chimichanga", "fug", "daiquiri", "Zamboni", "kazoo", "cromulent", "Munchkin")

lottery <- lottery |>
  mutate(flag = if_else(word %in% add_flag, "Y", flag))

print(lottery$word[lottery$flag == "Y"])

# two element: seaborgium, yttrium
# two scrumptious

lottery <- lottery |>
  mutate(word_lower = str_to_lower(word)) |>
  left_join(parts_of_speech, by = c("word_lower" = "word"), relationship = "many-to-many") |>
  mutate(pos = str_squish(str_remove(pos, "\\(.*\\)"))) |>
  distinct()

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

word_dates <- lottery |>
  distinct(word) |>
  mutate(first_use = map_chr(word, possibly(get_mw_date, NA_character_))) |>
  mutate(
    first_use_year = if_else(
      str_detect(first_use, "century"),
      (parse_number(first_use) - 1) * 100 + 50,  # "14th century" -> 1350
      parse_number(first_use)                     # "circa 1450" -> 1450
    ),
    specific = if_else(str_detect(first_use, "\\d{4}") %in% TRUE, "Y", "N")
  )

p_length <- lottery |>
  distinct(word, n_letters, flag) |>
  arrange(desc(flag == "Y")) |>
  group_by(n_letters) |>
  mutate(stack = row_number()) |>
  ungroup() |>
  ggplot(aes(x = n_letters, y = stack, fill = flag)) +
  geom_tile(width = 0.8, height = 0.8) +
  scale_fill_manual(values = c(N = "grey70", Y = "#000000"), guide = "none") +
  scale_x_continuous(breaks = scales::breaks_width(1)) +
  labs(
    title = "Length of submitted words",
    subtitle = "Each square is one word. Jerk-words in black.",
    x = "Letters in word", y = NULL
  ) +
  theme_minimal(base_family = "serif") +
  theme(
    panel.grid = element_blank(),
    axis.text.y = element_blank(),
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    plot.title.position = "plot"
  )


p_years <- word_dates |>
  filter(!is.na(first_use_year)) |>
  ggplot(aes(x = first_use_year)) +
  geom_histogram(binwidth = 50, boundary = 0, fill = "grey70", color = "white") +
  scale_x_continuous(breaks = scales::breaks_width(100)) +
  labs(
    title = "When Miriam-Webster says the words originated",
    x = "Year of first known use", y = "Number of words"
  ) +
  theme_minimal(base_family = "serif") +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    plot.title.position = "plot"
  )

ggsave("word_lengths.png", p_length, width = 8, height = 5, dpi = 300, bg = "white")
ggsave("word_origins.png", p_years, width = 8, height = 5, dpi = 300, bg = "white")


