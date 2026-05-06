{{ config(materialized='table') }}
-- DQ Fix: 4 source rows have null employee_id and are excluded here
{{ staging_model('employees', 'employee_id', filter_condition='employee_id is not null') }}
