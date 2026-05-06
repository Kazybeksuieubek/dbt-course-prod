-- DQ Issue 1: source interview status values contain leading/trailing underscores
-- (e.g. __CANCELLED, COMPLETED__). The staging model normalises these via
-- REGEXP_REPLACE.
-- This test fails if any normalised status still starts or ends with an underscore.
select id, status from {{ ref('stg_interview') }} where status regexp '^_|_$'
