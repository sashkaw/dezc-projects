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

# Load the yellow data (don't need this for the question)
docker run -it \
    --network=docker-workshop_db-net \
    taxi_ingest:v001 \
    --pg-user=root \
    --pg-pass=root \
    --pg-host=pgdatabase \
    --pg-port=5432 \
    --pg-db=ny_taxi \
    --target-table=yellow_taxi_trips_2021_2 \
    --chunksize=100000 \
    --url-suffix=yellow \
    --file-name="yellow_tripdata_2021-01.csv.gz"

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
    WHERE DATE(lpep_pickup_datetime) BETWEEN DATE('2019-10-01') AND DATE('2019-11-01')
        AND DATE(lpep_dropoff_datetime) BETWEEN DATE('2019-10-01') AND DATE('2019-11-01')
)
SELECT 
    seg,
    count(*) AS n
FROM tmp
GROUP BY seg
ORDER BY seg;
```

### Answer:
```
104,838; 199,013; 109,645; 27,688; 35,202
```
*Note: slight difference between ingested data and solution*

## Question 4. Longest trip for each day
Which was the pick up day with the longest trip distance? Use the pick up time for your calculations.

## TODO: Finish this

