with 
trips as (
    select
        year,
        month,
        unique_row_id,
        dispatching_base_num,
        pickup_datetime,
        dropOff_datetime,
        SR_Flag,
        Affiliated_base_number,
        pickup_location_id,
        pickup_borough,
        pickup_zone,
        dropoff_location_id,
        dropoff_borough,
        dropoff_zone,
        timestamp_diff(dropoff_datetime, pickup_datetime, SECOND) AS trip_duration
    from {{ ref('dim_fhv_trips') }}
)
select
    year,
    month,
    unique_row_id,
    dispatching_base_num,
    pickup_datetime,
    dropOff_datetime,
    SR_Flag,
    Affiliated_base_number,
    pickup_location_id,
    pickup_borough,
    pickup_zone,
    dropoff_location_id,
    dropoff_borough,
    dropoff_zone,
    trip_duration,
    percentile_cont(trip_duration, 0.90) over (
        partition by year, month, pickup_location_id, dropoff_location_id
    ) as p90
from trips