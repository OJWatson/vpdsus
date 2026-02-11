# GHO fixtures

These files are pinned samples from the WHO GHO OData API.

They are used in unit tests to avoid network access and to ensure that:

- URL/query construction is stable
- Parsing/standardisation to package columns is stable
- ISO3 standardisation behaves as expected

Each fixture should have a corresponding `*.meta.json` file recording:

- the exact URL requested
- retrieval time (UTC)
- endpoint/indicator code
- filter parameters (country/year)

Fixtures are intentionally tiny (typically `top=5` and filtered to a single country/year).
