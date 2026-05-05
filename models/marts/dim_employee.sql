{{ config(materialized='table') }}

select
    offset::bigint as _offset,
    id,
    job_function_id,
    primary_skill_id,
    production_category,
    employment_status,
    org_category,
    org_category_type,
    work_start_date,
    work_end_date,
    is_active,
    to_timestamp_ntz(row_valid_from::bigint / 1000000) as valid_from_datetime,
    to_timestamp_ntz(row_valid_to::bigint / 1000000) as valid_to_datetime

from {{ ref('stg_employee') }}
