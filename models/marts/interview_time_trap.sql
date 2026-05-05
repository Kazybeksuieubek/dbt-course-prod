{{ config(materialized='table') }}

{#
    Config-driven interview time trap model.
    Add new traps via the `interview_time_traps` variable in dbt_project.yml
    without modifying this file.

    Supported trap_type values:
        within_interview   – duration between two status transitions of the same interview
        between_interviews – duration from one interview type's status to the next
                             interview type's creation for the same candidate
#}
{% set traps = var('interview_time_traps', []) %}

-- Collect all statuses needed so we can pivot them in one CTE
{% set statuses_needed = [] %}
{% for trap in traps %}
    {% if trap.trap_type == 'within_interview' %}
        {% if trap.start_status not in statuses_needed %}
            {% do statuses_needed.append(trap.start_status) %}
        {% endif %}
        {% if trap.end_status   not in statuses_needed %}
            {% do statuses_needed.append(trap.end_status) %}
        {% endif %}
    {% elif trap.trap_type == 'between_interviews' %}
        {% if trap.start_status not in statuses_needed %}
            {% do statuses_needed.append(trap.start_status) %}
        {% endif %}
    {% endif %}
{% endfor %}

with
    interview_history as (select * from {{ ref('stg_interview') }}),

    interview_status_times as (
        select
            id as interview_id,
            candidate_id,
            type as interview_type,
            min(created_at) as created_at
            {%- for status in statuses_needed %}
                ,
                max(
                    case when status = '{{ status }}' then updated_at end
                ) as {{ status | lower }}_at
            {%- endfor %}
        from interview_history
        group by id, candidate_id, type
    )

{% if traps | length == 0 %}

    select
        null::varchar as candidate_id,
        null::varchar as interview_time_trap_name,
        null::float as trap_duration,
        null::timestamp_ntz as trap_start_datetime,
        null::timestamp_ntz as trap_end_datetime,
        null::varchar as trap_start_interview_id
    where false

{% else %}

    {% for trap in traps %}
        {% if not loop.first %}
            union all
        {% endif %}

        -- {{ trap.name }}
        {% if trap.trap_type == 'within_interview' %}
            select
                candidate_id,
                '{{ trap.name }}' as interview_time_trap_name,
                datediff(
                    'second',
                    {{ trap.start_status | lower }}_at,
                    {{ trap.end_status   | lower }}_at
                )
                / 3600.0 as trap_duration,
                {{ trap.start_status | lower }}_at as trap_start_datetime,
                {{ trap.end_status   | lower }}_at as trap_end_datetime,
                interview_id as trap_start_interview_id
            from interview_status_times
            where
                {{ trap.start_status | lower }}_at is not null
                and {{ trap.end_status   | lower }}_at is not null

        {% elif trap.trap_type == 'between_interviews' %}
            select
                si.candidate_id,
                '{{ trap.name }}' as interview_time_trap_name,
                datediff('second', si.{{ trap.start_status | lower }}_at, ei.created_at)
                / 3600.0 as trap_duration,
                si.{{ trap.start_status | lower }}_at as trap_start_datetime,
                ei.created_at as trap_end_datetime,
                si.interview_id as trap_start_interview_id
            from interview_status_times si
            join
                interview_status_times ei
                on si.candidate_id = ei.candidate_id
                and ei.interview_type = '{{ trap.end_interview_type }}'
                and ei.created_at > si.{{ trap.start_status | lower }}_at
            where
                si.interview_type = '{{ trap.start_interview_type }}'
                and si.{{ trap.start_status | lower }}_at is not null
            qualify
                row_number() over (partition by si.interview_id order by ei.created_at)
                = 1
        {% endif %}

    {% endfor %}

{% endif %}
