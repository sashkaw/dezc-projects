select
    service_type,
    year,
    month,
    percentile_cont(fare_amount, 0.97) over (partition by service_type, year, month) AS p97,
    percentile_cont(fare_amount, 0.95) over (partition by service_type, year, month) AS p95,
    percentile_cont(fare_amount, 0.90) over (partition by service_type, year, month) AS p90
from {{ ref('fct_trips') }}
where year between 2019 and 2020
    and fare_amount > 0
    and trip_distance > 0
    and payment_type_description in ('Cash', 'Credit card')