select
    -- Extra dimensions
    extract(YEAR FROM f.pickup_datetime) AS year,
    extract(MONTH FROM f.pickup_datetime) AS month,

    -- FHV core data
    f.unique_row_id,
    f.dispatching_base_num,
    f.pickup_datetime,
    f.dropOff_datetime,
    f.SR_Flag,
    f.Affiliated_base_number,
    
    -- Location details (enriched with human-readable zone names from dimension)
    f.PUlocationID as pickup_location_id,
    pickup_zone.borough as pickup_borough,
    pickup_zone.zone as pickup_zone,
    f.DOlocationID as dropoff_location_id,
    dropoff_zone.borough as dropoff_borough,
    dropoff_zone.zone as dropoff_zone

from {{ ref('stg_fhv') }} as f
-- LEFT JOIN preserves all trips even if zone information is missing or unknown
left join {{ ref('dim_zones') }} as pickup_zone
    on f.PUlocationID = pickup_zone.location_id
left join {{ ref('dim_zones') }} as dropoff_zone
    on f.DOlocationID = dropoff_zone.location_id