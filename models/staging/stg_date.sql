{{ config(materialized='table') }}

with
    date_spine as (
        -- generate one row per day from 2020-01-01 to 2029-12-31 (3653 days)
        select dateadd(day, seq4(), '2020-01-01'::date) as date
        from table(generator(rowcount => 3653))
    )

select
    date,
    year(date) as year,
    quarter(date) as quarter,
    month(date) as month,
    day(date) as day,
    weekofyear(date) as week,
    dayofweek(date) as day_of_week,
    dayname(date) as day_name,
    monthname(date) as month_name,
    dayofweekiso(date) in (6, 7) as is_weekend,
    false as is_holiday

from date_spine
