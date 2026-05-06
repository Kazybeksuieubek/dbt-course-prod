{#
    Generates a full-history SCD2 staging model for a raw source table.

    Reads column mappings (renames, type casts, custom expressions) from the
    staging_column_config seed. Adds row_valid_from / row_valid_to / row_is_active
    validity fields using a LEAD window over the entity's update timestamp.

    Parameters:
        source_table     – raw table name matching staging_column_config.raw_table_name
        primary_key      – raw column name identifying the entity (used for PARTITION BY)
        filter_condition – optional SQL WHERE predicate (using raw column names) applied
                           after deduplication; e.g. 'employee_id is not null'
#}
{% macro staging_model(source_table, primary_key, filter_condition=none) %}

    {%- set config_query -%}
    select
        raw_column_name,
        target_column_name,
        target_data_type,
        custom_expression
    from {{ ref('staging_column_config') }}
    where raw_table_name = '{{ source_table }}'
    order by target_order_num
    {%- endset -%}

    {%- if execute -%}
        {%- set results = run_query(config_query) -%} {%- set columns = results.rows -%}
    {%- else -%} {%- set columns = [] -%}
    {%- endif -%}

    with
        source as (
            select *
            from {{ source('raw', source_table) }}
            -- DQ Fix: deduplicate CDC replay — keep the latest row per offset
            qualify
                row_number() over (partition by _offset order by _updated_micros desc)
                = 1
        ),

        with_validity as (
            select
                *,
                _updated_micros as row_valid_from,
                coalesce(
                    lead(_updated_micros) over (
                        partition by {{ primary_key }} order by _updated_micros
                    ),
                    9558613439000000
                ) as row_valid_to
            from source
        )

    select
        {%- for row in columns %}
            {%- set raw_col     = row[0] %}
            {%- set target_col  = row[1] %}
            {%- set target_type = row[2] %}
            {%- set custom_expr = row[3] %}
            {%- if custom_expr is not none and custom_expr | trim != '' %}
                {{ custom_expr }} as {{ target_col }},
            {%- elif target_type == 'TIMESTAMP_NTZ' %}
                to_timestamp_ntz({{ raw_col }}::number / 1000000) as {{ target_col }},
            {%- elif target_type == 'BOOLEAN' %}
                {{ raw_col }}::boolean as {{ target_col }},
            {%- elif target_type == 'NUMBER' %}
                {{ raw_col }}::number as {{ target_col }},
            {%- else %} {{ raw_col }}::varchar as {{ target_col }},
            {%- endif %}
        {%- endfor %}
        row_valid_from,
        row_valid_to,
        (row_valid_to = 9558613439000000)::int as row_is_active

    from with_validity
    {%- if filter_condition is not none and filter_condition | trim != '' %}
        where {{ filter_condition }}
    {%- endif %}

{% endmacro %}
