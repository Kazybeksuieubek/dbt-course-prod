{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        pre_hook=[
            "{% if is_incremental() %}\
            UPDATE {{ this }} t\
            SET row_valid_to = src.min_new_micros,\
                row_is_active = 0\
            FROM (\
                SELECT id, MIN(_updated_micros) AS min_new_micros\
                FROM {{ source('raw', 'interviews') }}\
                WHERE _offset > (SELECT MAX(offset) FROM {{ this }})\
                GROUP BY id\
            ) src\
            WHERE t.id = src.id\
              AND t.row_valid_to = 9558613439000000\
            {% endif %}"
        ]
    )
}}

{{ staging_model('interviews', 'id') }}
