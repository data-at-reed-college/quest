# vaccination rates: United States and Oregon
# Run from the vaccines/ folder.

library(tidyverse)
library(ggtext)

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
    year = as.integer(str_sub(year_season, 1, 4)) + 1L,  # spring the school year ended
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
    year = as.integer(str_sub(year_season, 1, 4)) + 1L,  # spring the season ended
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

# --- COVID: adults 18+ up to date (CDC NIS-FRVM) ------------------------
# Source: "COVID-19 Vaccination Coverage, Overall and by Selected Demographics
# and Jurisdiction, Among Adults 18 Years and Older, by Season"
# https://data.cdc.gov/Vaccinations/COVID-19-Vaccination-Coverage-Overall-and-by-Selecte/ksfb-ug5d
# Coverage = % of adults up to date with that season's COVID vaccine. Only
# 2023-24 onward exists, and estimates are cumulative by week, so every season
# is compared at the same point in the season: the latest week reached by the
# current (partial) season.

covid_url <- "https://data.cdc.gov/resource/ksfb-ug5d.csv"

covid_raw <- covid_url |>
  str_c(
    "?$where=", URLencode(
      "geographic_name in ('National','Oregon') AND demographic_level='Overall' AND indicator_label='Up-to-date'",
      reserved = TRUE
    ),
    "&$limit=5000"
  ) |>
  read_csv(show_col_types = FALSE)

covid_weekly <- covid_raw |>
  mutate(
    week_ending = as.Date(week_ending),
    geography = if_else(geographic_name == "National", "United States", geographic_name)
  )

# Calendar date the current season has reached, restated in each season's
# own year (the season runs fall to spring, so Jan-Jul falls in the later year)
current_end <- covid_weekly |>
  filter(covid_season == max(covid_season)) |>
  summarize(max(week_ending)) |>
  pull()

covid_weekly <- covid_weekly |>
  mutate(
    season_start = as.integer(str_sub(covid_season, 1, 4)),
    target = make_date(
      season_start + (month(current_end) < 8), month(current_end), day(current_end)
    ),
    days_off = abs(as.numeric(week_ending - target, units = "days"))
  )

covid <- covid_weekly |>
  filter(days_off == min(days_off), !is.na(estimate), .by = c(covid_season, geography)) |>
  transmute(
    geography,
    season = str_c(str_sub(covid_season, 1, 4), "-", str_sub(covid_season, 8, 9)),
    year = as.integer(str_sub(covid_season, 1, 4)) + 1L,  # spring the season ended
    covid_coverage = estimate,
    ci_95 = str_c(
      round(estimate - ci_half_width_95pct, 1), " to ",
      round(estimate + ci_half_width_95pct, 1)
    ),
    n_surveyed = unweighted_sample_size,
    as_of = month_week
  )

# --- Combine MMR, flu and COVID -----------------------------------------
# What we plot: kindergarten MMR, adult flu and adult COVID, for the US and
# Oregon. Each measure keeps its own seasons (MMR: 2016-17 to 2025-26, flu:
# 2015-16 to 2024-25, COVID: 2023-24 to 2025-26, compared at the same point
# in the season). year is the spring the season ended (2025-26 -> 2026).
# pp_change_yoy: change in percentage points from the previous season
# pp_change_since_start: change in percentage points from the first season shown

rates <- bind_rows(
  mmr |>
    transmute(geography, measure = "MMR, kindergarten", year, coverage = mmr_coverage),
  flu |>
    filter(age_group == "Adults (18+)") |>
    transmute(geography, measure = "Flu, adults", year, coverage = flu_coverage),
  covid |>
    transmute(geography, measure = "COVID, adults", year, coverage = covid_coverage)
) |>
  arrange(measure, geography, year) |>
  mutate(
    pp_change_yoy = round(coverage - lag(coverage), 1),
    pp_change_since_start = round(coverage - first(coverage), 1),
    .by = c(measure, geography)
  )

write_csv(rates, "data/vaccination_rates.csv")

print(rates, n = Inf)

# --- Plot: change in coverage since each measure's first year (black and white) ---

# Panel labels: measure name, then each geography's starting coverage
panel_labels <- rates |>
  arrange(measure, desc(geography), year) |>   # US first, then Oregon
  summarize(
    start = str_c(
      if_else(geography == "Oregon", "Oregon", "US"), " start: ",
      format(round(first(coverage), 1), nsmall = 1), "%"
    ) |> first(),
    .by = c(measure, geography)
  ) |>
  summarize(start = str_flatten(start, "<br>"), .by = measure) |>
  mutate(
    short = c("MMR, kindergarten" = "MMR", "Flu, adults" = "Flu", "COVID, adults" = "COVID")[measure],
    panel = str_c("**", short, "**<br><span style='font-size:8.5pt'>", start, "</span>")
  )

rates_plot <- rates |>
  left_join(select(panel_labels, measure, panel), by = "measure") |>
  mutate(
    year = if_else(measure == "MMR, kindergarten", year - 1L, year),  # plot MMR on the start-year labels to match flu
    measure = factor(
      panel,
      levels = panel_labels$panel[match(c("MMR, kindergarten", "Flu, adults", "COVID, adults"), panel_labels$measure)]
    ),
    geography = factor(geography, levels = c("United States", "Oregon"))
  )

# Vertical gridlines at every year: darker for even years, lighter for odd
year_lines <- rates_plot |>
  distinct(measure, year) |>
  mutate(even = year %% 2 == 0)

p <- ggplot(rates_plot, aes(year, pp_change_since_start, linetype = geography, shape = geography)) +
  geom_vline(data = filter(year_lines, !even), aes(xintercept = year), color = "grey85", linewidth = 0.25) +
  geom_vline(data = filter(year_lines, even), aes(xintercept = year), color = "grey60", linewidth = 0.25) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 2, fill = "white") +
  facet_wrap(~measure, nrow = 1, scales = "free_x") +
  scale_linetype_manual(values = c("United States" = "solid", "Oregon" = "dashed")) +
  scale_shape_manual(values = c("United States" = 16, "Oregon" = 21)) +
  scale_x_continuous(
    breaks = \(x) {
      b <- scales::breaks_pretty(n = 4)(x)
      b[b == round(b) & b >= x[1] & b <= x[2]]  # whole years only
    },
    labels = \(x) str_c("'", str_sub(x, 3, 4))
  ) +
  labs(
    title = "Change in Vaccination Coverage Over Time",
    x = NULL, y = "Change in % Since Start Year", linetype = NULL, shape = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid = element_blank(),
    panel.grid.major.y = element_line(color = "grey85", linewidth = 0.25),
    plot.title = element_text(face = "bold", hjust = 0.5),
    plot.title.position = "plot",
    strip.text = element_markdown(hjust = 0.5, lineheight = 1.2),
    legend.position = "bottom",
    legend.direction = "horizontal",
    axis.title.y = element_text(size = 11),
    panel.spacing = unit(1.2, "lines")
  )
p

ggsave("images/vaccination_change.png", p, width = 10, height = 3.8, dpi = 300, bg = "white")
ggsave("images/vaccination_change.pdf", p, width = 10, height = 3.8)
