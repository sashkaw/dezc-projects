## Question 1. Understanding Docker images

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

### Answer:
`postgres:5432`

## Prepare the Data

```
cd 01-docker-terraform/docker-workshop

# Start postgres and pgadmin services
docker-compose up -d

# Build the ingestion image
docker build -t taxi_ingest:v001 --file ./Dockerfile .
docker build -t taxi_ingest_parquet:v001 --file ./parquet.Dockerfile .

# Load the green data
docker run -it \
    --network=docker-workshop_db-net \
    taxi_ingest_parquet:v001 \
    --pg-user=root \
    --pg-pass=root \
    --pg-host=pgdatabase \
    --pg-port=5432 \
    --pg-db=ny_taxi \
    --target-table=green_taxi_trips_2025_11 \
    --url-suffix=trip-data \
    --file-name="green_tripdata_2025-11.parquet"

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

## Question 3. Counting short trips

For the trips in November 2025 (lpep_pickup_datetime between '2025-11-01' and '2025-12-01', exclusive of the upper bound), how many trips had a `trip_distance` of less than or equal to 1 mile?

### Steps:

```
SELECT
    COUNT(*)
FROM green_taxi_trips_2025_11
WHERE
    DATE(lpep_pickup_datetime) >= DATE('2025-11-01')
    AND DATE(lpep_pickup_datetime) < DATE('2025-12-01')
    AND trip_distance <= 1;
```

### Answer:

`8,007`


## Question 4. Longest trip for each day

Which was the pick up day with the longest trip distance? Only consider trips with `trip_distance` less than 100 miles (to exclude data errors).

Use the pick up time for your calculations.

```
WITH tmp AS (
    SELECT
    TO_CHAR(DATE(lpep_pickup_datetime), 'YYYY-mm-dd') AS pickup_dt,
    *
    FROM green_taxi_trips_2025_11
    WHERE trip_distance < 100
)
SELECT
    pickup_dt,
    MAX(trip_distance)
FROM tmp
GROUP BY pickup_dt
ORDER BY MAX(trip_distance) DESC;
```

### Answer:

`2025-11-14`

## Question 5. Biggest pickup zone

Which was the pickup zone with the largest `total_amount` (sum of all trips) on November 18th, 2025?

### Steps:
```
SELECT
    z."Zone",
    SUM(t.total_amount) AS sum_amt
FROM green_taxi_trips_2025_11 AS t
JOIN taxi_zone_lookup AS z
ON t."PULocationID" = z."LocationID"
WHERE DATE(t.lpep_pickup_datetime) = '2025-11-18'
GROUP BY t."PULocationID", z."Zone"
ORDER BY sum(t.total_amount) DESC
LIMIT 1;
```

### Answer:

`East Harlem North`

## Question 6. Largest tip

For the passengers picked up in the zone named "East Harlem North" in November 2025, which was the drop off zone that had the largest tip?

Note: it's `tip` , not `trip`. We need the name of the zone, not the ID.

## Steps:
```
WITH tmp AS (
    SELECT
        zpu."Zone" AS pickup_zone,
        zdo."Zone" AS dropoff_zone,
        t.*
    FROM green_taxi_trips_2025_11 AS t
    JOIN taxi_zone_lookup AS zpu
    ON t."PULocationID" = zpu."LocationID"
    JOIN taxi_zone_lookup AS zdo
    ON t."DOLocationID" = zdo."LocationID"
    WHERE DATE(t.lpep_pickup_datetime) BETWEEN '2025-11-01' AND '2025-11-30'
        AND zpu."Zone" = 'East Harlem North'
)
SELECT
    dropoff_zone,
    MAX(tip_amount) AS max_tip
FROM tmp
GROUP BY dropoff_zone
ORDER BY MAX(tip_amount) DESC
LIMIT 1;
```

## Answer:

`Yorkville West`

## Question 7. Terraform Workflow

Which of the following sequences, respectively, describes the workflow for:
1. Downloading the provider plugins and setting up backend,
2. Generating proposed changes and auto-executing the plan
3. Remove all resources managed by terraform`

## Answer

`terraform init, terraform apply -auto-approve, terraform destroy`
