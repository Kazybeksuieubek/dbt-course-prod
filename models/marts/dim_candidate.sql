{{ config(materialized='table') }}

select
    offset::bigint as _offset,
    id,
    primary_skill_id,
    staffing_status,
    english_level,
    job_function_id,
    to_timestamp_ntz(row_valid_from::bigint / 1000000) as valid_from_datetime,
    to_timestamp_ntz(row_valid_to::bigint / 1000000) as valid_to_datetime

from {{ ref('stg_candidate') }}
