# Rental Properties dbt Pipeline

## Overview

This project builds an analytics-ready dataset for rental property listings using **dbt Core** and **DuckDB**.

The pipeline transforms three source CSV datasets:

- `LISTINGS.csv` — listing, host, property, pricing, and review attributes
- `CALENDAR.csv` — daily listing availability, reservations, pricing, and stay requirements
- `AMENITIES_CHANGELOG.csv` — historical changes to listing amenities

The final output is `mart_listings_daily`, a daily listing-level mart with a grain of:

> **One row per listing per calendar date**

The mart combines daily availability and reservation information with listing attributes, host verification flags, and the historical amenity state that was valid on each calendar date.

---

## Technology

- dbt Core 1.12.3
- dbt-duckdb 1.11.0
- DuckDB
- SQL
- Jinja

DuckDB is used as the local analytical database, allowing the project to run without an external data warehouse.

---

## Project Structure

```text
dbt_takehome/
├── macros/
│   ├── clean_string.sql
│   └── pivot_boolean_columns.sql
│
├── models/
│   ├── staging/
│   │   ├── stg_amenities_changelog.sql
│   │   ├── stg_calendar.sql
│   │   └── stg_listings.sql
│   │
│   ├── snapshot_models/
│   │   └── snapshot_amenities_changelog.sql
│   │
│   ├── intermediate/
│   │   ├── amenities_changelog/
│   │   ├── calendar_listings/
│   │   ├── host_verifications/
│   │   └── listings/
│   │
│   └── marts/
│       └── mart_listings_daily.sql
│
├── seeds/
│   └── rental_properties_data/
│       ├── AMENITIES_CHANGELOG.csv
│       ├── CALENDAR.csv
│       ├── LISTINGS.csv
│       └── properties.yml
│
├── tests/
├── dbt_project.yml
├── requirements.txt
└── README.md
```

Each model has an accompanying `.yml` file containing model and column documentation as well as applicable generic data tests.

---

## Data Pipeline

The project follows a layered dbt architecture:

```text
Seeds
  ↓
Staging
  ↓
Snapshot / Intermediate Models
  ↓
Final Mart
```

### Listings

```text
LISTINGS
   ↓
stg_listings
   ├─────────────────────────────→ int_listings
   ↓                                  ↑
int_host_verifications_long           │
   ↓                                  │
int_host_verifications_wide ──────────┘
```

`stg_listings` cleans and standardizes listing attributes while preserving one row per listing.

Host verification values are parsed into a list, exploded into a long-form intermediate model, and dynamically pivoted into boolean verification columns.

`int_listings` combines the cleaned listing attributes with these dynamically generated host verification flags.

### Calendar

```text
CALENDAR
   ↓
stg_calendar
   ↓
int_calendar_listing_daily
```

The raw calendar data can contain multiple source records for a listing and date.

`int_calendar_listing_daily` aggregates these records to:

> **One row per `listing_id` + `calendar_date`**

Daily measures include availability, reservation count, reservation IDs, nightly price, and minimum/maximum stay requirements.

### Historical Amenities

```text
AMENITIES_CHANGELOG
        ↓
stg_amenities_changelog
        ↓
snapshot_amenities_changelog
        ↓
int_amenities_changelog_long
        ↓
int_amenities_changelog_standardized
        ↓
int_amenities_changelog_wide
```

The amenities changelog is used to reconstruct the historical amenity state of each listing.

Each amenity snapshot receives a validity period:

```text
dbt_valid_from → dbt_valid_to
```

The next recorded amenity change ends the previous state one day before the new state begins. The latest recorded state remains valid through the current date.

Amenity arrays are then exploded into individual values and standardized to consolidate semantically similar amenities.

Examples include:

- `body soap`, `conditioner`, `shampoo`, and `shower gel` → `shower essentials`
- `baking sheet` → `cooking basics`
- `coffee machine` → `coffee maker`
- supported HDTV/streaming descriptions → `smart tv`
- cable-related descriptions → `cable tv`

Finally, amenities are dynamically pivoted into boolean columns while preserving the historical validity periods.

---

## Final Mart

`mart_listings_daily` uses the daily calendar model as its driving dataset.

It combines:

1. Daily calendar and reservation metrics
2. Listing and host attributes
3. Dynamic host verification flags
4. Historical amenity flags

Historical amenities are joined using their validity windows:

```sql
calendar.listing_id = amenities.listing_id
AND calendar.calendar_date
    BETWEEN amenities.dbt_valid_from
        AND amenities.dbt_valid_to
```

This ensures that each calendar date receives the amenity configuration that was valid at that point in time rather than simply using the listing's most recent amenities.

The final mart has a grain of:

> **One row per `listing_id` + `calendar_date`**

---

## Dynamic Column Generation

Amenities and host verification methods contain categorical values that are not necessarily known in advance.

Rather than hard-coding every possible value, the project dynamically discovers distinct values and generates boolean columns using dbt/Jinja and the reusable `pivot_boolean_columns` macro.

For example, amenity values such as:

```text
wifi
washer
air conditioning
```

are transformed into columns such as:

```text
wifi | washer | air_conditioning
```

with boolean values indicating whether the listing had the corresponding amenity.

This allows newly observed standardized amenities or host verification methods to automatically become columns during future dbt runs.

---

## Reusable Macros

### `clean_string`

Provides reusable string-cleaning logic across staging models.

Centralizing this logic avoids repeating the same string-cleaning SQL throughout the project.

### `pivot_boolean_columns`

Generates boolean columns from a dynamic list of categorical values.

The macro is reused for:

- Amenities
- Host verification methods

It also converts source values into SQL-safe column aliases.

---

## Source Data Handling

The source CSV files are loaded as dbt seeds.

DuckDB normally infers CSV column types automatically. Explicit seed types are used only where source values make inference unreliable or require cleaning before conversion.

For example:

- `CALENDAR.RESERVATION_ID` contains the literal string `"NULL"`, so it is loaded as `VARCHAR` and cleaned/cast in staging.
- `LISTINGS.PRICE` contains currency formatting such as `$`, so it is loaded as `VARCHAR` and converted to a numeric value in staging.

This allows ingestion to preserve problematic raw values while staging models are responsible for producing clean analytical types.

---

## Data Quality Tests

The project uses both dbt generic tests and custom singular SQL tests.

### Generic Tests

Model `.yml` files contain reusable tests including:

- `not_null`
- `unique`
- `accepted_values`

For example, `snapshot_amenities_changelog` includes a unique `snapshot_key` generated from the listing and change timestamp.

### Business-Rule Tests

Custom singular tests validate business and modeling assumptions including:

- Listings must accommodate at least one guest
- Bedroom, bed, and bathroom counts cannot be negative
- Listing price cannot be negative
- Review count and review score cannot be negative
- Last review date cannot precede first review date
- Minimum and maximum night requirements must be valid
- A listing/date should not contain more than one reservation
- Daily calendar records must be unique at `listing_id + calendar_date`
- Amenity validity periods cannot end before they begin
- Historical amenity periods for a listing cannot overlap
- The final mart must be unique at `listing_id + calendar_date`

The historical overlap and final-grain tests are particularly important because overlapping amenity validity periods could otherwise multiply rows during the temporal join.

---

## Key Design Decisions

### Historical Amenity States

Amenities are modeled historically rather than joining the current amenity state to every calendar date.

This prevents future amenity changes from being incorrectly applied to historical dates.

### Listing-Level Amenity Validity Windows

Amenity validity periods preserve the complete listing snapshot rather than independently collapsing each amenity's lifetime.

This ensures historical states remain mutually exclusive and allows a calendar date to match at most one amenity state.

### Dynamic Pivots

Amenities and host verification values are dynamically pivoted rather than hard-coded, allowing the models to adapt to newly observed values.

### Views vs. Tables

Lightweight cleaning and transformation models are generally materialized as views.

Models involving aggregation, dynamic pivots, historical state reconstruction, or final analytical outputs are materialized as tables where appropriate.

### Warehouse Optimization

Some models include partitioning or clustering configurations to demonstrate how larger warehouse-backed implementations could be optimized.

Because this project runs locally on a small DuckDB dataset, these configurations are not required for current performance.

---

## Running the Project

### 1. Clone the repository

```bash
git clone https://github.com/ebarwinczak/dbt-takehome.git
cd dbt-takehome
```

### 2. Create a Python virtual environment

```bash
python -m venv dbt-env
source dbt-env/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure the dbt profile

Create or update:

```text
~/.dbt/profiles.yml
```

with:

```yaml
dbt_takehome:
  target: dev

  outputs:
    dev:
      type: duckdb
      path: dev.duckdb
      threads: 4
```

The generated `dev.duckdb` database is intentionally excluded from version control.

### 5. Verify the connection

```bash
dbt debug
```

### 6. Load the source CSVs

```bash
dbt seed --full-refresh
```

### 7. Build and test the project

```bash
dbt build
```

This builds the models and executes both generic and singular data tests.

---

## dbt Documentation

Generate the dbt documentation artifacts with:

```bash
dbt docs generate
```

Then launch the local documentation site:

```bash
dbt docs serve
```

The generated documentation contains model descriptions, column definitions, tests, and the project lineage DAG.

---

## Useful Development Commands

Validate project configuration:

```bash
dbt parse
```

Run all models:

```bash
dbt run
```

Run all tests:

```bash
dbt test
```

Build the final mart and all upstream dependencies:

```bash
dbt build --select +mart_listings_daily
```

Build the amenities snapshot and all downstream dependencies:

```bash
dbt build --select snapshot_amenities_changelog+
```

---

## Assumptions

The following assumptions were made while modeling the source data:

- The amenities changelog represents historical changes to a listing's complete amenity set.
- A new amenities changelog event becomes effective on `CHANGE_AT`.
- The previous amenity state is valid through the day before the next change.
- The latest amenity state is considered valid through the current date.
- A listing should have at most one distinct reservation on a calendar date.
- Nightly price and minimum/maximum stay requirements should be consistent for a listing/date when multiple raw calendar records exist.
- Missing review dates are permitted for listings without applicable review history.
- Missing host location components are preserved as null rather than broadly inferred from incomplete location strings.