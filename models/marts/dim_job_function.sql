{{ config(materialized='table') }}

select
    offset::bigint as _offset,
    id,
    base_name,
    category,
    is_active,
    level,
    track,
    seniority_level,
    seniority_index,
    valid_from_datetime,
    valid_to_datetime

from {{ ref('stg_job_function') }}
