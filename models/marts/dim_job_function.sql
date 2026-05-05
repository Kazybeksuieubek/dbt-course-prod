{{ config(materialized='table') }}

select
    id, base_name, category, is_active, level, track, seniority_level, seniority_index

from {{ ref('stg_job_function') }}
where row_is_active = 1
