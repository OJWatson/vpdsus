# Demography fixture provenance (WPP-like)

This repository includes a tiny **offline** demography fixture:

- `inst/extdata/demography_wpp_like_small.csv`

## Purpose

This file is used in tests and offline vignettes to validate the *shape* and
transformation contract for `get_demography(source = "fixture_wpp")` without:

- network access
- reliance on large external datasets

## Origin

The values are **synthetic / illustrative** (not an official UN WPP extract).
They were constructed to be internally consistent for unit testing:

- rows represent single-year age groups for a single ISO3/year
- `pop` is positive
- `births` is positive and constant within ISO3/year

## Expected columns

- `iso3` (ISO3 code)
- `year` (integer)
- `age` (integer)
- `pop` (population count)
- `births` (births count)
