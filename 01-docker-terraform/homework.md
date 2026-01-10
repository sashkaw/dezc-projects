## Question 1. Understanding docker first run
Run docker with the python:3.12.8 image in an interactive mode, use the entrypoint bash.

What's the version of pip in the image?

### Steps:
```
docker run -it \
    --rm \
    --entrypoint=bash \
    --name=q1 \
    python:3.12.8

pip --version
```

### Answer:
`24.3.1`

## Question 2. Understanding Docker networking and docker-compose
Given the following docker-compose.yaml, what is the hostname and port that pgadmin should use to connect to the postgres database?

### Steps:
- We can use the `container_name` for the `db` service to find the `hostname` value used for the shared network.
- We get the `port` from the right-hand side (port within the container) of the `ports` mapping for the same service.

### Answer:
`postgres:5432`

## Prepare Postgres
```
# Start postgres and pgadmin services
docker-compose up -d

# Build the ingestion image
docker build -t taxi_ingest:v001 .

# Load the green data
docker run -it \
    --network=docker-workshop_db-net \
    taxi_ingest:v001 \
    --pg-user=root \
    --pg-pass=root \
    --pg-host=pgdatabase \
    --pg-port=5432 \
    --pg-db=ny_taxi \
    --target-table=green_taxi_trips_2019_11 \
    --chunksize=100000 \
    --url-suffix=green \
    --file-name="green_tripdata_2019-10.csv.gz"

# Load the zone data
docker run -it \
    --network=docker-workshop_db-net \
    taxi_ingest:v001 \
    --pg-user=root \
    --pg-pass=root \
    --pg-host=pgdatabase \
    --pg-port=5432 \
    --pg-db=ny_taxi \
    --target-table=taxi_zone_lookup \
    --chunksize=100000 \
    --url-suffix=misc \
    --file-name="taxi_zone_lookup.csv"
```

## Question 3. Trip Segmentation Count
During the period of October 1st 2019 (inclusive) and November 1st 2019 (exclusive), how many trips, respectively, happened:

### Steps:
```
WITH
tmp AS (
    SELECT
        CASE
            WHEN trip_distance <= 1 THEN '0: <=1 MILE'
            WHEN trip_distance > 1 AND trip_distance <= 3 THEN '1: 1 - 3 MILES'
            WHEN trip_distance > 3 AND trip_distance <= 7 THEN '2: 3 - 7 MILES'
            WHEN trip_distance > 7 AND trip_distance <= 10 THEN '3: 7 - 10 MILES'
            WHEN trip_distance > 10 THEN '4: >10 MILES'
            ELSE '5: OTHER'
        END AS seg,
        *
    FROM green_taxi_trips_2019_11
    WHERE
        DATE(lpep_pickup_datetime) >= DATE('2019-10-01')
        AND DATE(lpep_pickup_datetime) < DATE('2019-11-01')
        AND DATE(lpep_dropoff_datetime) >= DATE('2019-10-01')
        AND DATE(lpep_dropoff_datetime) < DATE('2019-11-01')
)
SELECT 
    seg,
    count(*) AS n
FROM tmp
GROUP BY seg
ORDER BY seg;
```

### Answer:
`104,802; 198,924; 109,603; 27,678; 35,189`

## Question 4. Longest trip for each day
Which was the pick up day with the longest trip distance? Use the pick up time for your calculations.

```
WITH tmp AS (
    SELECT
    TO_CHAR(DATE(lpep_pickup_datetime), 'YYYY-mm-dd') AS pickup_dt,
    *
    FROM green_taxi_trips_2019_11
    WHERE DATE(lpep_pickup_datetime) IN (
        DATE('2019-10-11'), DATE('2019-10-24'), DATE('2019-10-26'), DATE('2019-10-31')
    )
)
SELECT
    pickup_dt,
    MAX(trip_distance)
FROM tmp
GROUP BY pickup_dt
ORDER BY MAX(trip_distance) DESC;
```

### Answer:
`2019-10-31`

## Question 5. Three biggest pickup zones
Which were the top pickup locations with over 13,000 in total_amount (across all trips) for 2019-10-18?

### Steps:
```
SELECT
    z."Zone",
    SUM(t.total_amount) AS sum_amt
FROM green_taxi_trips_2019_11 AS t
JOIN taxi_zone_lookup AS z
ON t."PULocationID" = z."LocationID"
WHERE DATE(t.lpep_pickup_datetime) = '2019-10-18'
GROUP BY t."PULocationID", z."Zone"
HAVING SUM(t.total_amount) > 13000
ORDER BY sum(t.total_amount) DESC LIMIT 5;
```

### Answer:
`East Harlem North, East Harlem South, Morningside Heights`

## Question 6. Largest tip
For the passengers picked up in October 2019 in the zone named "East Harlem North" which was the drop off zone that had the largest tip?

## Steps:
```
WITH tmp AS (
    SELECT
        zpu."Zone" AS pickup_zone,
        zdo."Zone" AS dropoff_zone,
        t.*
    FROM green_taxi_trips_2019_11 AS t
    JOIN taxi_zone_lookup AS zpu
    ON t."PULocationID" = zpu."LocationID"
    JOIN taxi_zone_lookup AS zdo
    ON t."DOLocationID" = zdo."LocationID"
    WHERE DATE(t.lpep_pickup_datetime) BETWEEN '2019-10-01' AND '2019-10-31'
        AND zpu."Zone" = 'East Harlem North'
)
SELECT
    dropoff_zone,
    MAX(tip_amount) AS max_tip
FROM tmp
GROUP BY dropoff_zone
ORDER BY MAX(tip_amount) DESC LIMIT 5;
```

## Answer:
`JFK Airport`

## Question 7. Terraform Workflow
Which of the following sequences, respectively, describes the workflow for:

1. Downloading the provider plugins and setting up backend,
2. Generating proposed changes and auto-executing the plan
3. Remove all resources managed by terraform

## Answer
`terraform init, terraform apply -auto-approve, terraform destroy`
