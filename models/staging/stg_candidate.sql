{{ config(materialized='view') }}

with
    source as (select * from {{ source('raw', 'candidates') }}),

    latest as (
        select
            *,
            row_number() over (
                partition by candidate_id order by _updated_micros desc
            ) as _row_num
        from source
    )

select
    _offset::bigint as offset,
    candidate_id::varchar as id,
    primary_skill_id::varchar as primary_skill_id,
    staffing_status::varchar as staffing_status,
    english_level::varchar as english_level,
    job_function_id::varchar as job_function_id,
    to_timestamp_ntz(_created_micros::number / 1000000) as created_at,
    to_timestamp_ntz(_updated_micros::number / 1000000) as updated_at

from latest
where _row_num = 1
