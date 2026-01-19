import json
from kafka import KafkaProducer
import pandas as pd
from time import time
import numpy as np

def json_serializer(data):
    return json.dumps(data).encode("utf-8")

server = "localhost:9092"
topic_name = "green-trips"

producer = KafkaProducer(
    bootstrap_servers=[server],
    value_serializer=json_serializer,
)

producer.bootstrap_connected()

data_url = "https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz"
cols = [
    "lpep_pickup_datetime",
    "lpep_dropoff_datetime",
    "PULocationID",
    "DOLocationID",
    "passenger_count",
    "trip_distance",
    "tip_amount",
]
dtypes = {
    "PULocationID": "Int64",
    "DOLocationID": "Int64",
    "passenger_count": "Int64",
    "trip_distance": "Float64",
    "tip_amount": "Float64",
}
parse_dates = ["lpep_pickup_datetime", "lpep_dropoff_datetime"]
df = pd.read_csv(data_url, usecols=cols, dtype=dtypes, parse_dates=parse_dates)
# df.head()

# Convert Timestamp columns to strings for JSON serialization
date_fmt = "%Y-%m-%d %H:%M:%S"
df["lpep_pickup_datetime"] = df["lpep_pickup_datetime"].dt.strftime(date_fmt)
df["lpep_dropoff_datetime"] = df["lpep_dropoff_datetime"].dt.strftime(date_fmt)
# df.head()

# Convert NAs to None for JSON serialization
df = df.fillna(value=np.nan).replace([np.nan], [None])
# df.tail()

rows = df.to_dict(orient="records")
t0 = time()
# TODO: Update this
for i, message in enumerate(rows[:100]):
    if i % 100000 == 0:
        print(f"Sending row #{i} with message:\n{message}\n\n")
    try:
        producer.send(topic_name, value=message)
    except Exception as e:
        print(f"Failed to write to kafka with error {e} and data {message}")

producer.flush()

t1 = time()
took = t1 - t0
print(f"Time to send the entire dataset and flush: {took:.02f}")
print(f"# Rows: {len(rows)}")


