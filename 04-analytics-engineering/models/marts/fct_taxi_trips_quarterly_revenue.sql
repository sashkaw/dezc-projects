with
quarterly as (
  select
    service_type,
    year_quarter,
    sum(total_amount) AS quarterly_revenue
  from {{ ref('fct_trips') }}
  where year between 2019 and 2020
  group by service_type, year_quarter
  order by service_type, year_quarter
),
comparison as (
  select
    service_type,
    year_quarter,
    quarterly_revenue,
    lag(quarterly_revenue, 4) over (
      partition by service_type
      order by year_quarter
    ) as prev_year_revenue
  from quarterly
)
select
  service_type,
  year_quarter,
  quarterly_revenue,
  prev_year_revenue,
  (quarterly_revenue - prev_year_revenue) / (abs(prev_year_revenue)) * 100 as yoy_growth
from comparison

