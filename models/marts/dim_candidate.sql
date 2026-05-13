{{ config(materialized='table') }}

select
    offset::bigint as _offset,
    id,
    primary_skill_id,
    staffing_status,
    english_level,
    job_function_id,
    valid_from_datetime,
    valid_to_datetime

from {{ ref('stg_candidate') }}
