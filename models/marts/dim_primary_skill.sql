{{ config(materialized='table') }}

select id, is_active, type, name, url, parent_id

from {{ ref('stg_skill') }}
where row_is_active = 1
