{{ config(materialized='table') }}

select
    offset::bigint as _offset,
    id,
    is_active,
    type,
    name,
    url,
    parent_id,
    valid_from_datetime,
    valid_to_datetime

from {{ ref('stg_skill') }}
