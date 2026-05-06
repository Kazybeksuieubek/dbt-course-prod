-- DQ Issue 2: some employee records have work_end_date earlier than work_start_date,
-- which is logically impossible. Surfaced here as a warning so the issue is visible
-- without blocking downstream models. Fix approach: treat affected rows as data errors
-- and exclude or null-out work_end_date where work_end_date < work_start_date.
{{ config(severity='warn') }}

select id, work_start_date, work_end_date
from {{ ref('stg_employee') }}
where
    row_is_active = 1 and work_end_date is not null and work_end_date < work_start_date
