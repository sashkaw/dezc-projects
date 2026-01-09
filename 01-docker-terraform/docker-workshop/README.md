## Running the pipeline
```
# Start postgres and pgadmin services
docker-compose up -d

# Build the ingestion image
docker build -t taxi_ingest:v001 .

# Load the yellow data
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


## Troubleshooting

### Service account key generation
- To remove constraint blocking service account key creation, first make sure you can edit the policy:
```
gcloud organizations add-iam-policy-binding YOUR_ORG_ID --member='user:YOUR_EMAIL' --role='roles/orgpolicy.policyAdmin'
```
- Then navigate to GCP console, set policy to `Override parent's policy`, and change setting to `Not Enforced`
- NOTE: Make sure to remove both:
    - `iam.managed.disableServiceAccountKeyCreation`
    - `iam.disableServiceAccountKeyCreation`
