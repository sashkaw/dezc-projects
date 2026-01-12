#!/bin/bash

# Set GCP project
gcloud set project dezc-dev

# Download data
mkdir tmp
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
mv taxi_zone_lookup.csv tmp/taxi_zone_lookup.csv

# Load to GCS bucket
gsutil cp tmp/taxi_zone_lookup.csv gs://dezc-dev-terra-bucket/

# Load to BigQuery from GCS bucket
bq load \
    --source_format=CSV \
    --autodetect \
    example_dataset.taxi_zone_lookup \
    gs://dezc-dev-terra-bucket/taxi_zone_lookup.csv