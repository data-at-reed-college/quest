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


# --- Flu: end-of-season coverage (CDC FluVaxView) -----------------------
# Source: "Influenza Vaccination Coverage for All Ages (6+ Months)"
# https://data.cdc.gov/Vaccinations/Influenza-Vaccination-Coverage-for-All-Ages-6-Months-/vh55-3he6
# NIS-Flu / BRFSS survey estimates of the % vaccinated against seasonal flu.
# The dataset gives cumulative coverage by month; month 5 (May) is the
# end-of-season figure.

flu_url <- "https://data.cdc.gov/resource/vh55-3he6.csv"

flu_raw <- flu_url |>
  str_c(
    "?$where=", URLencode(
      "geography in ('United States','Oregon') AND dimension_type='Age' AND vaccine='Seasonal Influenza' AND month='5'",
      reserved = TRUE
    ),
    "&$limit=5000"
  ) |>
  read_csv(show_col_types = FALSE)

# The 2023-24 season labels the age groups differently
age_groups <- c(
  "6 Months - 17 Years"        = "Children (6 months-17 years)",
  ">=18 Years"                 = "Adults (18+)",
  "Greater than 18 Years flu"  = "Adults (18+)",
  ">=6 Months"                 = "All ages (6 months+)",
  "Greater than 6 Months flu"  = "All ages (6 months+)"
)

flu <- flu_raw |>
  filter(dimension %in% names(age_groups)) |>
  transmute(
    geography,
    season = year_season,
    year = as.integer(str_sub(year_season, 1, 4)),  # fall the season started
    age_group = unname(age_groups[dimension]),
    flu_coverage = as.numeric(coverage_estimate),
    ci_95 = `_95_ci`,
    n_surveyed = population_sample_size
  ) |>
  filter(!is.na(flu_coverage), year >= max(year) - 9) |>  # last 10 seasons
  arrange(age_group, geography, year)


ggplot(flu, aes(x = year, y = flu_coverage, color = age_group)) +
  geom_line() +
  labs(title = "Flu Vaccination Coverage by Age Group and Year", x = "Year", y = "Coverage (%)") +
  theme_minimal() + 
  scale_color_discrete(name = "Age Group") +
  facet_wrap(~geography)

# --- Combine MMR and flu ------------------------------------------------
# One row per vaccine measure x geography x season. Each measure keeps its
# own last 10 seasons (MMR: 2016-17 to 2025-26, flu: 2015-16 to 2024-25).
# pp_change_yoy: change in percentage points from the previous season
# pp_change_since_start: change in percentage points from the first season shown

rates <- bind_rows(
  mmr |>
    transmute(
      geography, measure = "MMR, kindergarten (2 doses)", season = school_year, year,
      coverage = mmr_coverage, ci_95 = NA_character_, n_surveyed
    ),
  flu |>
    transmute(
      geography, measure = str_c("Flu, ", str_to_lower(age_group)), season, year,
      coverage = flu_coverage, ci_95, n_surveyed
    )
) |>
  arrange(measure, geography, year) |>
  mutate(
    pp_change_yoy = round(coverage - lag(coverage), 1),
    pp_change_since_start = round(coverage - first(coverage), 1),
    .by = c(measure, geography)
  )

write_csv(rates, "data/vaccination_rates.csv")

print(rates, n = Inf)
