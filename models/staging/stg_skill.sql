{{ config(materialized='view') }}

with
    source as (select * from {{ source('raw', 'skills') }}),

    latest as (
        select
            *,
            row_number() over (
                partition by id order by _updated_micros desc
            ) as _row_num
        from source
    )

select
    _offset::bigint as offset,
    id::varchar as id,
    is_active::boolean as is_active,
    is_primary::boolean as is_primary,
    is_key::boolean as is_key,
    nullif(trim(is_key_reason), '') is not null as is_key_reason,
    type::varchar as type,
    name::varchar as name,
    url::varchar as url,
    parent_id::varchar as parent_id,
    to_timestamp_ntz(_created_micros::number / 1000000) as created_at,
    to_timestamp_ntz(_updated_micros::number / 1000000) as updated_at

from latest
where _row_num = 1
