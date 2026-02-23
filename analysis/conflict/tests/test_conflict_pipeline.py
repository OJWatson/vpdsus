from pathlib import Path

import numpy as np
import pandas as pd

from analysis.conflict.conflict_pipeline import (
    aggregate_conflict_annual,
    aggregate_conflict_monthly,
    harmonize_conflict_events,
    merge_conflict_with_panel,
)


def test_harmonize_and_aggregate_shapes():
    raw = pd.DataFrame(
        {
            "id": [1, 2, 3],
            "year": [2020, 2020, 2021],
            "type_of_violence": [1, 2, 3],
            "country": ["Kenya", "Kenya", "Uganda"],
            "date_start": ["2020-01-15", "2020-01-30", "2021-06-01"],
            "date_end": ["2020-01-15", "2020-01-30", "2021-06-01"],
            "best": [10, 5, 2],
            "high": [12, 6, 2],
            "low": [8, 4, 1],
        }
    )

    clean, qa = harmonize_conflict_events(raw)
    assert qa.raw_rows == 3
    assert qa.date_parse_failures == 0
    assert clean["iso3"].isna().sum() == 0

    monthly = aggregate_conflict_monthly(clean)
    assert len(monthly) == 2  # Kenya Jan 2020 + Uganda Jun 2021

    annual = aggregate_conflict_annual(monthly)
    assert len(annual) == 2

    kenya_2020 = annual[(annual["iso3"] == "KEN") & (annual["year"] == 2020)].iloc[0]
    assert kenya_2020["conflict_events_total"] == 2
    assert kenya_2020["conflict_fatalities_best"] == 15


def test_merge_conflict_with_panel_zero_fill_in_coverage_window():
    panel = pd.DataFrame(
        {
            "iso3": ["KEN", "KEN", "KEN", "UGA"],
            "year": [1988, 2020, 2021, 2020],
            "cases": [100, 120, 130, 80],
            "coverage": [0.8, 0.82, 0.83, 0.79],
            "pop_total": [1_000_000, 1_050_000, 1_070_000, 800_000],
        }
    )

    conflict = pd.DataFrame(
        {
            "iso3": ["KEN", "UGA"],
            "year": [2020, 2020],
            "conflict_events_total": [5, 1],
            "conflict_fatalities_best": [50, 3],
            "conflict_fatalities_high": [60, 3],
            "conflict_fatalities_low": [40, 2],
            "conflict_state_based_events": [2, 1],
            "conflict_non_state_events": [1, 0],
            "conflict_one_sided_events": [2, 0],
            "conflict_any_event": [1, 1],
            "conflict_any_fatality": [1, 1],
        }
    )

    merged = merge_conflict_with_panel(panel, conflict, conflict_year_start=2020, conflict_year_end=2021)

    # In-window but missing conflict row -> zero-filled
    ken_2021 = merged[(merged["iso3"] == "KEN") & (merged["year"] == 2021)].iloc[0]
    assert ken_2021["conflict_data_available"]
    assert ken_2021["conflict_events_total"] == 0

    # Out-of-window -> remains missing
    ken_1988 = merged[(merged["iso3"] == "KEN") & (merged["year"] == 1988)].iloc[0]
    assert not ken_1988["conflict_data_available"]
    assert np.isnan(ken_1988["conflict_events_total"])

    # Incidence created
    uga_2020 = merged[(merged["iso3"] == "UGA") & (merged["year"] == 2020)].iloc[0]
    assert uga_2020["measles_incidence_per_100k"] > 0
