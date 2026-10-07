# vaccination rates: United States and Oregon
# Run from the vaccines/ folder.

library(tidyverse)

# --- MMR: kindergarten coverage (CDC SchoolVaxView) ---------------------
# Source: "Vaccination Coverage and Exemptions among Kindergartners"
# https://data.cdc.gov/Vaccinations/Vaccination-Coverage-and-Exemptions-among-Kindergartners/ijqb-a7ye
# Coverage = % of kindergartners with the full MMR series (2 doses).

kindergarten_url <- "https://data.cdc.gov/resource/ijqb-a7ye.csv"

mmr_raw <- kindergarten_url |>
  str_c(
    "?$where=", URLencode("vaccine='MMR' AND geography in ('United States','Oregon')", reserved = TRUE),
    "&$limit=1000"
  ) |>
  read_csv(show_col_types = FALSE)

mmr <- mmr_raw |>
  transmute(
    geography,
    school_year = year_season,
    year = as.integer(str_sub(year_season, 1, 4)),  # fall of the school year
    mmr_coverage = suppressWarnings(as.numeric(coverage_estimate)),
    n_surveyed = suppressWarnings(as.numeric(population_sample_size)),
    survey_type
  ) |>
  filter(!is.na(mmr_coverage), year >= max(year) - 9) |>  # last 10 school years
  arrange(geography, year)

write_csv(mmr, "data/mmr_kindergarten.csv")

print(mmr, n = Inf)
