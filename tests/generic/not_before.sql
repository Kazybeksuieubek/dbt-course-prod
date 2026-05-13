{#
    Generic test: fails if column_name < start_column for any non-null row.
    Useful for asserting chronological ordering between two date/timestamp columns.

    Parameters:
        model        – model reference (injected by dbt)
        column_name  – the "later" column (e.g. work_end_date)
        start_column – the "earlier" column (e.g. work_start_date)
        row_condition – optional SQL filter applied before the check (e.g. 'row_is_active = 1')
#}
{% test not_before(model, column_name, start_column, row_condition=none) %}

    select {{ column_name }}, {{ start_column }}
    from {{ model }}
    where
        {{ column_name }} is not null and {{ column_name }} < {{ start_column }}
        {%- if row_condition %} and {{ row_condition }} {%- endif %}

{% endtest %}
