{#
    Wraps a staging model to return only the currently active row per entity
    (i.e. row_is_active = 1 — the most recent version of each record).

    Parameter:
        staging_model_ref – name of the dbt staging model to reference
#}
{% macro latest_staging_model(staging_model_ref) %}

    select * from {{ ref(staging_model_ref) }} where row_is_active = 1

{% endmacro %}
