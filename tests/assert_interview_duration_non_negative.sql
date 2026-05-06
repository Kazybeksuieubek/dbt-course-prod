-- DQ Issue 3: a subset of interviews have negative interview_duration or
-- feedback_delay,
-- caused by out-of-order status transitions recorded in the source system.
-- Surfaced as warn to monitor volume without failing CI.
{{ config(severity='warn') }}

select id, interview_duration, feedback_delay
from {{ ref('fct_interview') }}
where
    (interview_duration is not null and interview_duration < 0)
    or (feedback_delay is not null and feedback_delay < 0)
