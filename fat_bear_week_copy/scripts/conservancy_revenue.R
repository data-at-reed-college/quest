library(tidyverse)

# Katmai Conservancy revenue by year (IRS Form 990s)
revenue <- tribble(
  ~year, ~total_revenue,
  2017,  203307,
  2018,  215785,
  2019,  23982,
  2020,  549706,
  2021,  788985,
  2022,  650561,
  2023,  1628460,
  2024,  1325542
)

summary_tbl <- read_csv("data/summary.csv", show_col_types = FALSE, col_types = cols(
  champion = col_character(),
  runner_up = col_character()
))

summary_tbl <- summary_tbl |>
  left_join(revenue, by = "year")

write_csv(summary_tbl, "data/summary.csv")

print(summary_tbl, n = 12)
