"""
02_transform.py
ETL for the WUENIC immunization project (West Africa, DTP1 / DTP3 / MCV1 / MCV2).

Extract : read the 'country' sheet of the UNICEF WUENIC 2025 workbook
Transform: keep needed columns/rows, run quality checks, add gap metrics
Load    : write two clean CSV files to data/processed/

Run from anywhere:   python python/02_transform.py
"""

from pathlib import Path

import pandas as pd

# ---------------------------------------------------------------------------
# Settings (change these in ONE place)
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent   # folder that contains data/
RAW_FILE = PROJECT_ROOT / "data" / "raw" / "wuenic2025rev_web-update.xlsx"
OUT_DIR = PROJECT_ROOT / "data" / "processed"

START_YEAR = 2000          # change to 2010 if you prefer a shorter window
TARGET = 95                # herd-immunity target for measles, used as the gap benchmark

KEEP_COLUMNS = ["iso3c", "country", "vaccine", "year", "target_grp", "coverage"]
VACCINES = ["dtp1", "dtp3", "mcv1", "mcv2"]
WEST_AFRICA = [
    "BEN", "BFA", "CIV", "CPV", "GHA", "GIN", "GMB", "GNB",
    "LBR", "MLI", "MRT", "NER", "NGA", "SEN", "SLE", "TGO",
]


def extract() -> pd.DataFrame:
    """Read the raw 'country' sheet."""
    df = pd.read_excel(RAW_FILE, sheet_name="country")
    print(f"Extracted raw sheet: {df.shape[0]:,} rows, {df.shape[1]} columns")
    return df


def transform(df: pd.DataFrame) -> pd.DataFrame:
    """Keep the columns and rows we need (same recipe as the Power Query steps)."""
    df = df[KEEP_COLUMNS]
    df = df[df["iso3c"].isin(WEST_AFRICA)]
    df = df[df["vaccine"].isin(VACCINES)]
    df = df[df["year"] >= START_YEAR]
    df = df.sort_values(["iso3c", "vaccine", "year"]).reset_index(drop=True)
    print(f"After filters: {df.shape[0]:,} rows, {df.shape[1]} columns")
    return df


def check_quality(df: pd.DataFrame) -> None:
    """Stop the script loudly if the data is not what we expect."""
    assert df["iso3c"].nunique() == 16, "Expected 16 countries"
    assert set(df["vaccine"].unique()) == set(VACCINES), "Unexpected vaccine list"
    assert df["year"].min() >= START_YEAR, "A year before START_YEAR slipped in"
    assert df.isna().sum().sum() == 0, "Missing values found"
    assert df["coverage"].between(0, 100).all(), "Coverage outside 0-100"
    dupes = df.duplicated(["iso3c", "vaccine", "year"]).sum()
    assert dupes == 0, f"{dupes} duplicate country/vaccine/year rows"
    print("Quality checks passed: 16 countries, no nulls, no duplicates, coverage 0-100")


def add_long_metrics(df: pd.DataFrame) -> pd.DataFrame:
    """Gap to the 95% target for every row. Positive = below target."""
    out = df.copy()
    out["gap_to_95"] = TARGET - out["coverage"]
    out["below_95"] = out["gap_to_95"] > 0
    return out


def build_wide(df: pd.DataFrame) -> pd.DataFrame:
    """One row per country-year with one column per vaccine, plus derived metrics."""
    wide = (
        df.pivot(index=["iso3c", "country", "year"], columns="vaccine", values="coverage")
        .reset_index()
    )
    wide.columns.name = None
    wide = wide.rename(columns={v: f"{v}_coverage" for v in VACCINES})

    # Zero-dose children: those who never received even the first DTP dose.
    wide["zero_dose_pct"] = 100 - wide["dtp1_coverage"]

    # Dropout: share of children who started DTP but did not finish (DTP1 -> DTP3).
    wide["dtp_dropout_pct"] = (
        (wide["dtp1_coverage"] - wide["dtp3_coverage"]) / wide["dtp1_coverage"] * 100
    ).round(1)

    # Gap to target for each vaccine (positive = below 95).
    for v in VACCINES:
        wide[f"{v}_gap_to_95"] = TARGET - wide[f"{v}_coverage"]

    # Measles second-dose drop. NOTE: MCV1 uses 'si' and MCV2 uses 'y02' as the
    # denominator, so treat this as indicative, not a strict like-for-like drop.
    wide["mcv1_to_mcv2_drop"] = wide["mcv1_coverage"] - wide["mcv2_coverage"]
    return wide


def load(long_df: pd.DataFrame, wide_df: pd.DataFrame) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    long_path = OUT_DIR / "wuenic_west_africa_long.csv"
    wide_path = OUT_DIR / "wuenic_west_africa_wide.csv"
    long_df.to_csv(long_path, index=False, encoding="utf-8")
    wide_df.to_csv(wide_path, index=False, encoding="utf-8")
    print(f"Wrote {long_path.name}: {len(long_df):,} rows")
    print(f"Wrote {wide_path.name}: {len(wide_df):,} rows")


def main() -> None:
    raw = extract()
    clean = transform(raw)
    check_quality(clean)
    long_df = add_long_metrics(clean)
    wide_df = build_wide(clean)
    load(long_df, wide_df)


if __name__ == "__main__":
    main()
