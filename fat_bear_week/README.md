# Fat Bear Week 

Hand-compiled from NPS, Explore.org and news sources (see `sources.csv`). Can't find a lot of exact data for a lot of things. 

## Data Files
- `summary.csv`: one row per year, winning bears, runner up, entries, total vote estimates, total non-profit revenue
- `bears.csv`: one row per bear (40). `birth_year_est` is derived from the age/ID-year stated in bios; `birth_year_basis` says how.
- `appearances.csv`: bear × year. Full rosters for 2021–2026; for 2014–2020 only finalists (plus 480 in 2018) are listed.
- `sources.csv`: source key → URL.

## Scripts
- `conservancy_revenue.R`: scrapes of 990s to get revenue for Katmai Conservancy
- `analysis.R`: creates graphic

## Known problems
- **Rosters 2014–2020**: can't find these, can only get winner and runner up
- **Wonky 990**: no data until 2017; 2019 inexplicably low 
- **Bear 609 = 909 Jr.?**: Both are described as the 2022 Fat Bear Junior champion
- **128 Grazer's age**: 2024 bio says she was a cub in 2005; the 2022 bio says first identified 2009 at ~17–19; recorded birth year as 2004 
- **Sex unknown**: for 99, 775 Lefty and 132's 2021 cub 
- **Lineage**: not the greatest record, but is recorded for 14 bears, mostly the 409 → 909/910 line, the 435 line (89, 335, 719 → 519, 26?), the 128 line (428, 903, 128 Jr.) and 402 (503, 812?). `mother_basis` distinguishes stated / believed / suspected / inferred
