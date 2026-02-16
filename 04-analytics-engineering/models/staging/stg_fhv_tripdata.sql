select
    unique_row_id,
    dispatching_base_num,
    pickup_datetime,
    dropOff_datetime as dropoff_datetime,
    PUlocationID as pickup_location_id,
    DOlocationID as dropoff_location_id,
    SR_Flag AS sr_flag,
    Affiliated_base_number AS affiliated_base_number
from {{ source('raw', 'fhv_tripdata') }}
where dispatching_base_num is not null