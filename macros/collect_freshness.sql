{% macro snowflake__collect_freshness(source, loaded_at_field, filter) %}
    {% call statement('collect_freshness', fetch_result=True, auto_begin=False) -%}
        select
            max(
                to_timestamp_ntz({{ loaded_at_field }}::number / 1000000)
            ) as max_loaded_at,
            {{ current_timestamp() }} as snapshotted_at
        from {{ source }}
        {% if filter %} where {{ filter }} {% endif %}
    {%- endcall %}
    {{ return(load_result('collect_freshness')) }}
{% endmacro %}
