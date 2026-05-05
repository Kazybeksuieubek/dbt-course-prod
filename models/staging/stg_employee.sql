{{ config(materialized='table') }} {{ staging_model('employees', 'employee_id') }}
