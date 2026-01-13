## Question 1. Understanding docker first run

Run docker with the `python:3.13` image. Use an entrypoint `bash` to interact with the container.

What's the version of `pip` in the image?

### Steps:
```
docker run -it \
    --rm \
    --entrypoint=bash \
    --name=q1 \
    python:3.13

pip --version
```

### Answer:

`25.3`

## Question 2. Understanding Docker networking and docker-compose

Given the following `docker-compose.yaml`, what is the `hostname` and `port` that pgadmin should use to connect to the postgres database?

```yaml
services:
  db:
    container_name: postgres
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: 'postgres'
      POSTGRES_PASSWORD: 'postgres'
      POSTGRES_DB: 'ny_taxi'
    ports:
      - '5433:5432'
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
      PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
      - "8080:80"
    volumes:
      - vol-pgadmin_data:/var/lib/pgadmin

volumes:
  vol-pgdata:
    name: vol-pgdata
  vol-pgadmin_data:
    name: vol-pgadmin_data
```

### Steps:
- We can use the `container_name` for the `db` service to find the `hostname` value used for the shared network.
- We get the `port` from the right-hand side (port within the container) of the `ports` mapping for the same service.

### Answer:
`postgres:5432`

## Prepare Postgres

## TODO: Update this since hw changed -> need to get parquet file for Nov 2025

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
    --target-table=green_taxi_trips_2025_11 \
    --chunksize=100000 \
    --url-suffix=green \
    --file-name="green_tripdata_2025-11.csv.gz"

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

For the trips in November 2025 (lpep_pickup_datetime between '2025-11-01' and '2025-12-01', exclusive of the upper bound), how many trips had a `trip_distance` of less than or equal to 1 mile?

### Steps:
```
SELECT
    COUNT(*)
FROM green_taxi_trips_2019_11
WHERE
    DATE(lpep_pickup_datetime) >= '2025-11-01'
    AND DATE(lpep_pickup_datetime) < '2025-12-01'
    AND trip_distance <= 1;
```

### Answer:



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
