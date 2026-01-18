## Troubleshooting

- GCP Console seems to have a bug with the Dataproc `Regions` dropdown menu triggering a `'Server could not complete your request'` error. To fix this (temporarily), uncheck all the regions and select only the region for your cluster.

- Due to quota limits with the free GCP trial, only some regions offer N4 CPUs for VMs. For example, the below command fails for `us-west1` but succeeds for `us-east1`.

```
CLUSTER=<cluster_name>
REGION=<region_name>
PROJECT=<project_name>
CODE_BUCKET=<code_bucket_name>
DATA_BUCKET=<data_bucket_name>
DATASET=<bq_dataset_name>

gcloud dataproc clusters create "${CLUSTER}" \
    --enable-component-gateway \
    --region "${REGION}" \
    --no-address \
    --single-node \
    --master-machine-type n4-standard-2 \
    --master-boot-disk-type hyperdisk-balanced \
    --master-boot-disk-size 100
    --image-version 2.2-debian12 \
    --optional-components JUPYTER,DOCKER \
    --scopes 'https://www.googleapis.com/auth/cloud-platform' \
    --project "${PROJECT}"
```

- To run a Spark job:

```
# Copy PySpark code to GCS bucket
gsutil cp code/spark_standalone.py "gs://${CODE_BUCKET}/spark_standalone.py"

# Copy data to GCS bucket (same region)
gsutil -m cp -r code/data/pq/ "gs://${DATA_BUCKET}/pq"

# Submit PySpark job (same region)
# NOTE: Added `--properties` to fix memory issues

# To save results to GCS:
gcloud dataproc jobs submit pyspark "gs://${CODE_BUCKET}/spark_standalone.py" \
    --cluster="${CLUSTER}" \
    --region="${REGION}" \
    --properties spark.executor.memory=4g,spark.driver.memory=4g,spark.sql.shuffle.partitions=8 \
    -- --input_green="gs://${DATA_BUCKET}/pq/green/2020/*/" \
        --input_yellow="gs://${DATA_BUCKET}/pq/yellow/2020/*/" \
        --output="gs://${DATA_BUCKET}/report-2020"

# To save results to BigQuery:
# NOTE: The Dataproc service account must have the appropriate BigQuery permissions
gcloud dataproc jobs submit pyspark "gs://${CODE_BUCKET}/spark_standalone.py" \
    --cluster="${CLUSTER}" \
    --region="${REGION}" \
    --properties spark.executor.memory=4g,spark.driver.memory=4g,spark.sql.shuffle.partitions=8 \
    -- --input_green="gs://${DATA_BUCKET}/pq/green/2020/*/" \
        --input_yellow="gs://${DATA_BUCKET}/pq/yellow/2020/*/" \
        --output="${DATASET}.report_2020"

# SSH into Dataproc VM and forward the port for the history server
gcloud compute ssh "${CLUSTER}"-m \
  --project="${PROJECT}" \
  --zone="${REGION}"-d \
  --tunnel-through-iap \
  -- -NL 4040:localhost:18080
```


