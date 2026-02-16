## Setup

- See `flows/*.yml` for Kestra flows used to load in taxi and FHV data to BigQuery
- Install dbt core following the steps in the `README.md`
- Run these dbt commands
```
# Install dependencies
dbtcore deps

# Load taxi zone and payment type lookup table seed data
dbtcore seed

# Run dbt models
# NOTE: Just used single environment for simplicity
dbtcore build --target dev
```

## Question 1. dbt Lineage and Execution

Given a dbt project with the following structure:

```
models/
├── staging/
│   ├── stg_green_tripdata.sql
│   └── stg_yellow_tripdata.sql
└── intermediate/
    └── int_trips_unioned.sql (depends on stg_green_tripdata & stg_yellow_tripdata)
```

If you run `dbt run --select int_trips_unioned`, what models will be built?

### Answer

- `stg_green_tripdata`, `stg_yellow_tripdata`, and `int_trips_unioned` (upstream dependencies)

## Question 2. dbt Tests

You've configured a generic test like this in your `schema.yml`:

```yaml
columns:
  - name: payment_type
    data_tests:
      - accepted_values:
          arguments:
            values: [1, 2, 3, 4, 5]
            quote: false
```

Your model `fct_trips` has been running successfully for months. A new value `6` now appears in the source data.

What happens when you run `dbt test --select fct_trips`?

### Answer

- dbt will fail the test, returning a non-zero exit code

## Question 3. Counting Records in `fct_monthly_zone_revenue`

After running your dbt project, query the `fct_monthly_zone_revenue` model.

What is the count of records in the `fct_monthly_zone_revenue` model?

### Steps:
```
SELECT COUNT(*)
FROM example_dataset.fct_monthly_zone_revenue;
```

### Answer:

- 12,184

## Question 4. Best Performing Zone for Green Taxis (2020)

Using the `fct_monthly_zone_revenue` table, find the pickup zone with the **highest total revenue** (`revenue_monthly_total_amount`) for **Green** taxi trips in 2020.

Which zone had the highest revenue?

### Steps:

```
SELECT
  pickup_zone,
  SUM(revenue_monthly_total_amount) AS total_revenue
FROM example_dataset.fct_monthly_zone_revenue
WHERE service_type = 'Green'
  AND revenue_month BETWEEN '2020-01-01' AND '2020-12-31'
GROUP BY pickup_zone
ORDER BY SUM(revenue_monthly_total_amount) DESC
LIMIT 1;
```

### Answer:

- East Harlem North

## Question 5. Green Taxi Trip Counts (October 2019)

Using the `fct_monthly_zone_revenue` table, what is the **total number of trips** (`total_monthly_trips`) for Green taxis in October 2019?

### Steps:

```
SELECT
  SUM(total_monthly_trips) AS total_trips
FROM example_dataset.fct_monthly_zone_revenue
WHERE service_type = 'Green'
  AND revenue_month = '2019-10-01';
```

### Answer:

- 384,624

## Question 6. Build a Staging Model for FHV Data

Create a staging model for the **For-Hire Vehicle (FHV)** trip data for 2019.

1. Load the [FHV trip data for 2019](https://github.com/DataTalksClub/nyc-tlc-data/releases/tag/fhv) into your data warehouse
2. Create a staging model `stg_fhv_tripdata` with these requirements:
   - Filter out records where `dispatching_base_num IS NULL`
   - Rename fields to match your project's naming conventions (e.g., `PUlocationID` → `pickup_location_id`)

What is the count of records in `stg_fhv_tripdata`?

### Steps:

```
dbtcore build --target dev --select models/staging/stg_fhv_tripdata.sql
```

```
SELECT
  COUNT(*)
FROM example_dataset.stg_fhv_tripdata;
```

### Answer:

- 43,244,693