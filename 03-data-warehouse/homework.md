*NOTE: This homework was completed when the instructions were marked 'DRAFT', so may need to revisit before submitting.*

## Setup

- Run the following Kestra flow as a backfill from 2024-01-01 to 2024-06-02:
```
id: gcp_load_to_bucket
namespace: zoomcamp
description: |
  Best to add a label `backfill:true` from the UI to track executions created via a backfill.

inputs:
  - id: taxi
    type: SELECT
    displayName: Select taxi type
    values: [yellow, green]
    defaults: green

variables:
  url_prefix: "https://d37ci6vzurychx.cloudfront.net/trip-data"
  file: "{{inputs.taxi}}_tripdata_{{trigger.date | date('yyyy-MM')}}.parquet"
  gcs_file: "gs://{{kv('GCP_BUCKET_NAME')}}/{{vars.file}}"
  table: "{{kv('GCP_DATASET')}}.{{inputs.taxi}}_tripdata_{{trigger.date | date('yyyy_MM')}}"
  data: "{{outputs.extract.outputFiles[inputs.taxi ~ '_tripdata_' ~ (trigger.date | date('yyyy-MM')) ~ '.parquet']}}"

tasks:
  - id: set_label
    type: io.kestra.plugin.core.execution.Labels
    labels:
      file: "{{render(vars.file)}}"
      taxi: "{{inputs.taxi}}"

  - id: extract
    type: io.kestra.plugin.scripts.shell.Commands
    outputFiles:
      - "*.parquet"
    taskRunner:
      type: io.kestra.plugin.core.runner.Process
    commands:
      - wget -qO- "{{vars.url_prefix}}/{{render(vars.file)}}" > {{render(vars.file)}}

  - id: upload_to_gcs
    type: io.kestra.plugin.gcp.gcs.Upload
    from: "{{render(vars.data)}}"
    to: "{{render(vars.gcs_file)}}"

  - id: purge_files
    type: io.kestra.plugin.core.storage.PurgeCurrentExecutionFiles
    description: To avoid cluttering your storage, we will remove the downloaded files

pluginDefaults:
  - type: io.kestra.plugin.gcp
    values:
      serviceAccount: "{{secret('GCP_CREDS')}}"
      projectId: "{{kv('GCP_PROJECT_ID')}}"
      location: "{{kv('GCP_LOCATION')}}"
      bucket: "{{kv('GCP_BUCKET_NAME')}}"

triggers:
  - id: green_schedule
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 9 1 * *"
    inputs:
      taxi: green

  - id: yellow_schedule
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 10 1 * *"
    inputs:
      taxi: yellow
```

- Within BigQuery, run the following statements:
```
CREATE OR REPLACE EXTERNAL TABLE example_dataset.yellow_tripdata_2024_ext
(
    VendorID INTEGER OPTIONS (description = 'A code indicating the LPEP provider that provided the record. 1= Creative Mobile Technologies, LLC; 2= VeriFone Inc.'),
    tpep_pickup_datetime TIMESTAMP OPTIONS (description = 'The date and time when the meter was engaged'),
    tpep_dropoff_datetime TIMESTAMP OPTIONS (description = 'The date and time when the meter was disengaged'),
    passenger_count INTEGER OPTIONS (description = 'The number of passengers in the vehicle. This is a driver-entered value.'),
    trip_distance FLOAT64 OPTIONS (description = 'The elapsed trip distance in miles reported by the taximeter.'),
    RatecodeID INTEGER OPTIONS (description = 'The final rate code in effect at the end of the trip. 1= Standard rate 2=JFK 3=Newark 4=Nassau or Westchester 5=Negotiated fare 6=Group ride'),
    store_and_fwd_flag STRING OPTIONS (description = 'This flag indicates whether the trip record was held in vehicle memory before sending to the vendor, aka "store and forward," because the vehicle did not have a connection to the server. TRUE = store and forward trip, FALSE = not a store and forward trip'),
    PULocationID INTEGER OPTIONS (description = 'TLC Taxi Zone in which the taximeter was engaged'),
    DOLocationID INTEGER OPTIONS (description = 'TLC Taxi Zone in which the taximeter was disengaged'),
    payment_type INTEGER OPTIONS (description = 'A numeric code signifying how the passenger paid for the trip. 1= Credit card 2= Cash 3= No charge 4= Dispute 5= Unknown 6= Voided trip'),
    fare_amount FLOAT64 OPTIONS (description = 'The time-and-distance fare calculated by the meter'),
    extra FLOAT64 OPTIONS (description = 'Miscellaneous extras and surcharges. Currently, this only includes the $0.50 and $1 rush hour and overnight charges'),
    mta_tax FLOAT64 OPTIONS (description = '$0.50 MTA tax that is automatically triggered based on the metered rate in use'),
    tip_amount FLOAT64 OPTIONS (description = 'Tip amount. This field is automatically populated for credit card tips. Cash tips are not included.'),
    tolls_amount FLOAT64 OPTIONS (description = 'Total amount of all tolls paid in trip.'),
    improvement_surcharge FLOAT64 OPTIONS (description = '$0.30 improvement surcharge assessed on hailed trips at the flag drop. The improvement surcharge began being levied in 2015.'),
    total_amount FLOAT64 OPTIONS (description = 'The total amount charged to passengers. Does not include cash tips.'),
    congestion_surcharge FLOAT64 OPTIONS (description = 'Congestion surcharge applied to trips in congested zones')
)
OPTIONS (
    format = 'PARQUET',
    uris = ['gs://dezc-dev-terra-bucket/*.parquet']
);

CREATE OR REPLACE TABLE example_dataset.yellow_tripdata_2024
AS
SELECT
    MD5(CONCAT(
        COALESCE(CAST(VendorID AS STRING), ""),
        COALESCE(CAST(tpep_pickup_datetime AS STRING), ""),
        COALESCE(CAST(tpep_dropoff_datetime AS STRING), ""),
        COALESCE(CAST(PULocationID AS STRING), ""),
        COALESCE(CAST(DOLocationID AS STRING), "")
    )) AS unique_row_id,
    *
FROM example_dataset.yellow_tripdata_2024_ext;
```

## Question 1

What is count of records for the 2024 Yellow Taxi Data?

### Steps:
```
SELECT
    COUNT(unique_row_id)
FROM example_dataset.yellow_tripdata_2024;
```

### Answer:

`20,332,093`

## Question 2

Write a query to count the distinct number of PULocationIDs for the entire dataset on both the tables.
What is the estimated amount of data that will be read when this query is executed on the External Table and the Table?

### Steps:

```
SELECT
    COUNT(DISTINCT PULocationID)
FROM example_dataset.yellow_tripdata_2024_ext;

SELECT
    COUNT(DISTINCT PULocationID)
FROM example_dataset.yellow_tripdata_2024;
```

### Answer:

`0 MB for the External Table and 155.12 MB for the Materialized Table`

## Question 3

Write a query to retrieve the PULocationID from the table (not the external table) in BigQuery. Now write a query to retrieve the PULocationID and DOLocationID on the same table. Why are the estimated number of Bytes different?

### Steps:

```
SELECT
    PULocationID
FROM example_dataset.yellow_tripdata_2024;

SELECT
    PULocationID,
    DOLocationID
FROM example_dataset.yellow_tripdata_2024;
```

### Answer:

```
BigQuery is a columnar database, and it only scans the specific columns requested in the query. Querying two columns (PULocationID, DOLocationID) requires reading more data than querying one column (PULocationID), leading to a higher estimated number of bytes processed.
```

## Question 4

How many records have a fare_amount of 0?

### Steps:

```
SELECT
    count(unique_row_id)
FROM example_dataset.yellow_tripdata_2024
WHERE fare_amount = 0;
```

### Answer:

`8,333`

## Question 5

What is the best strategy to make an optimized table in Big Query if your query will always filter based on tpep_dropoff_datetime and order the results by VendorID (Create a new table with this strategy)

### Steps:

```
CREATE OR REPLACE TABLE example_dataset.yellow_tripdata_2024_partitioned
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorId
AS
SELECT
    *
FROM example_dataset.yellow_tripdata_2024;
```

### Answer:

`Partition by tpep_dropoff_datetime and Cluster on VendorID`

## Question 6

Write a query to retrieve the distinct VendorIDs between tpep_dropoff_datetime 2024-03-01 and 2024-03-15 (inclusive)

Use the materialized table you created earlier in your from clause and note the estimated bytes. Now change the table in the from clause to the partitioned table you created for question 5 and note the estimated bytes processed. What are these values? 

### Steps:

```
SELECT
  DISTINCT VendorId
FROM example_dataset.yellow_tripdata_2024
WHERE DATE(tpep_dropoff_datetime) BETWEEN '2024-03-01' AND '2024-03-15';

SELECT
  DISTINCT VendorId
FROM example_dataset.yellow_tripdata_2024_partitioned
WHERE DATE(tpep_dropoff_datetime) BETWEEN '2024-03-01' AND '2024-03-15';
```

### Answer:

`310.24 MB for non-partitioned table and 26.84 MB for the partitioned table`

## Question 7

Where is the data stored in the External Table you created?

### Answer:

`GCP Bucket`

## Question 8

It is best practice in Big Query to always cluster your data:

### Steps:

### Answer:

`False (depends on the data and query requirements)`

## Question 9

No Points: Write a SELECT count(*) query FROM the materialized table you created. How many bytes does it estimate will be read? Why?

### Steps:

```
SELECT
    COUNT(*)
FROM example_dataset.yellow_tripdata_2024;
```

### Answer:

```
BigQuery estimates that 0 bytes will be read, because BigQuery can retrieve the number of rows from the table metadata without scanning the actual data. The total rows for each table are stored within INFORMATION_SCHEMA.TABLE_STORAGE.
```

