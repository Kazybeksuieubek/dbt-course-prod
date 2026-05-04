{{ config(materialized='view') }}

with
    source as (select * from {{ source('raw', 'job_functions') }}),

    latest as (
        select
            *,
            row_number() over (
                partition by job_function_id order by _updated_micros desc
            ) as _row_num
        from source
    )

select
    _offset::bigint as offset,
    job_function_id::varchar as id,
    base_name::varchar as base_name,
    category::varchar as category,
    is_active::boolean as is_active,
    level::number as level,
    track::varchar as track,
    seniority_level::varchar as seniority_level,
    seniority_index::number as seniority_index,
    to_timestamp_ntz(_created_micros::number / 1000000) as created_at,
    to_timestamp_ntz(_updated_micros::number / 1000000) as updated_at

from latest
where _row_num = 1
