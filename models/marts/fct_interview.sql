{{ config(materialized='table') }}

with
    interview_history as (select * from {{ ref('stg_interview') }}),

    -- Latest state of each interview (for non-status attributes)
    interviews_latest as (select * from interview_history where row_is_active = 1),

    -- Pivot status timestamps: when did each interview reach each status?
    status_times as (
        select
            id,
            min(created_at) as created_at,
            max(case when status = 'REQUESTED' then updated_at end) as requested_at,
            max(case when status = 'SCHEDULED' then updated_at end) as scheduled_at,
            max(case when status = 'IN_PROGRESS' then updated_at end) as started_at,
            max(
                case when status = 'PENDING_FEEDBACK' then updated_at end
            ) as feedback_provided_at,
            max(case when status = 'COMPLETED' then updated_at end) as finished_at,
            max(case when status = 'CANCELLED' then updated_at end) as cancelled_at
        from interview_history
        group by id
    )

select
    i.id,
    i.candidate_type,
    dc._offset as candidate_offset,
    i.status,
    de._offset as interviewer_offset,
    i.location,
    i.is_logged,
    i.is_media_available,
    i.run_type,
    i.type,
    i.media_status,
    i.invite_answer_status,
    s.created_at::date as created_date,
    s.created_at as created_datetime,
    s.requested_at as requested_datetime,
    s.scheduled_at as scheduled_datetime,
    s.started_at as started_datetime,
    s.finished_at as finished_datetime,
    s.feedback_provided_at as feedback_provided_datetime,
    s.cancelled_at as cancelled_datetime,
    -- interview_duration: elapsed minutes from IN_PROGRESS → PENDING_FEEDBACK
    -- only online interviews have IN_PROGRESS status
    datediff('minute', s.started_at, s.feedback_provided_at) as interview_duration,
    -- feedback_delay: elapsed minutes from PENDING_FEEDBACK → COMPLETED
    datediff('minute', s.feedback_provided_at, s.finished_at) as feedback_delay

from interviews_latest i
left join status_times s on s.id = i.id
-- Point-in-time join: candidate state at moment of interview creation
left join
    {{ ref('dim_candidate') }} dc
    on dc.id = i.candidate_id
    and s.created_at >= dc.valid_from_datetime
    and s.created_at < dc.valid_to_datetime
-- Point-in-time join: interviewer (employee) state at moment of interview creation
left join
    {{ ref('dim_employee') }} de
    on de.id = i.interviewer_id
    and s.created_at >= de.valid_from_datetime
    and s.created_at < de.valid_to_datetime
