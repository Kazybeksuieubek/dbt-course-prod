{{ config(materialized='table') }}

with
    source as (select * from {{ source('raw', 'employees') }}),

    latest as (
        select
            *,
            row_number() over (
                partition by employee_id order by _updated_micros desc
            ) as _row_num
        from source
    )

select
    _offset::bigint as offset,
    employee_id::varchar as id,
    job_function_id::varchar as job_function_id,
    primary_skill_id::varchar as primary_skill_id,
    production_category::varchar as production_category,
    employment_status::varchar as employment_status,
    org_category::varchar as org_category,
    org_category_type::varchar as org_category_type,
    to_date(to_timestamp_ntz(work_start_micros::bigint / 1000000)) as work_start_date,
    to_date(to_timestamp_ntz(work_end_micros::bigint / 1000000)) as work_end_date,
    is_active::boolean as is_active,
    to_timestamp_ntz(_created_micros::number / 1000000) as created_at,
    to_timestamp_ntz(_updated_micros::number / 1000000) as updated_at

from latest
where _row_num = 1
