{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

with
    source as (
        select *
        from {{ source('raw', 'interviews') }}

        {% if is_incremental() %}
            where
                to_timestamp_ntz(_updated_micros::number / 1000000)
                > (select max(updated_at) from {{ this }})
        {% endif %}
    ),

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
    candidate_type::varchar as candidate_type,
    candidate_id::varchar as candidate_id,
    status::varchar as status,
    interviewer_id::varchar as interviewer_id,
    location::varchar as location,
    logged::boolean as is_logged,
    media_available::boolean as is_media_available,
    run_type::varchar as run_type,
    type::varchar as type,
    media_status::varchar as media_status,
    invite_answer_status::varchar as invite_answer_status,
    to_timestamp_ntz(_created_micros::number / 1000000) as created_at,
    to_timestamp_ntz(_updated_micros::number / 1000000) as updated_at

from latest
where _row_num = 1
