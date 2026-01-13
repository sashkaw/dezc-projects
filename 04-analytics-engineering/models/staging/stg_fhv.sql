select
    unique_row_id,
    dispatching_base_num,
    pickup_datetime,
    dropOff_datetime,
    PUlocationID,
    DOlocationID,
    SR_Flag,
    Affiliated_base_number
from {{ source('raw', 'fhv_tripdata') }}
where dispatching_base_num is not null