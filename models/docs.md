{% docs scd2_overview %}
Each row in this model represents **one version** of the record — not the record itself.
When a field changes in the source system, a new row is added rather than the old one being updated.
Two special columns track the lifetime of each version:

- **row_valid_from** — the moment this version became active (Unix microseconds).
- **row_valid_to** — the moment this version expired. A far-future sentinel value (`9558613439000000`, year 2272) means the row is the current version.
- **row_is_active** — `1` if this is the latest version of the record, `0` for historical versions.

This pattern is called **Slowly Changing Dimension Type 2 (SCD2)** and allows analysts to
reconstruct the exact state of any entity at any point in history.
{% enddocs %}


{% docs scd2_offset %}
The `_offset` (or `offset`) column is the **CDC (Change Data Capture) offset** from the
Kafka message queue — the sequential position of the event in the source stream.
It uniquely identifies each change event and is used as a surrogate key for SCD2 rows.

> **Data quality note:** The raw source may contain duplicate offsets due to CDC replay
> (the same message delivered more than once). The staging layer deduplicates these using
> `QUALIFY ROW_NUMBER() OVER (PARTITION BY _offset ...) = 1`.
{% enddocs %}


{% docs scd2_row_is_active %}
A flag (`1` / `0`) that indicates whether this row is the **current, active version** of
the record.

- `1` — this is the latest version; `row_valid_to` is the far-future sentinel.
- `0` — this is a historical version that has since been superseded.

Use `WHERE row_is_active = 1` to get a snapshot of the world as it looks today.
{% enddocs %}


{% docs fct_interview %}
The central fact table for interview analytics. Each row represents **one interview in its
latest state**, enriched with:

- **Pivoted status timestamps** — when the interview reached REQUESTED, SCHEDULED,
  IN_PROGRESS, PENDING_FEEDBACK, COMPLETED, and CANCELLED states.
- **Duration metrics** — `interview_duration` (time the interview itself took) and
  `feedback_delay` (time from interview end to feedback submission).
- **Point-in-time dimension keys** — `candidate_offset` and `interviewer_offset` link to the
  exact version of the candidate and employee records that were active *at the moment the
  interview was created*, preserving historical accuracy even as those records change over time.
{% enddocs %}


{% docs interview_duration %}
The elapsed time **in minutes** between the interview entering `IN_PROGRESS` status and
the interviewer submitting feedback (`PENDING_FEEDBACK` status).

This measures the **actual interview duration**, not the scheduled length.

> Only online interviews (`run_type = 'ONLINE'`) go through the `IN_PROGRESS` status, so
> this metric is `NULL` for onsite interviews.
> A negative value indicates out-of-order status transitions in the source system
> (known data quality issue, monitored via a `warn`-severity test).
{% enddocs %}


{% docs interview_time_trap %}
A **time trap** measures the elapsed time between two significant events in the candidate
hiring funnel. Unlike `fct_interview` (which measures what happened inside a single
interview), time traps can span *across* interviews to answer questions like:

> *"How long does it typically take from a candidate's HR interview ending to their first
> Technical interview being scheduled?"*

Traps are defined declaratively in `dbt_project.yml` under the `interview_time_traps`
variable, so new measurements can be added without changing SQL. Two trap types are
supported:

| Type | Measures |
|---|---|
| `within_interview` | Duration between two status transitions of the **same** interview |
| `between_interviews` | Duration from one interview's status to the **next** interview of a different type for the same candidate |
{% enddocs %}


{% docs pit_join %}
A **point-in-time (PIT) join** looks up the dimension record that was active at a specific
moment in the past, rather than the current record.

For example, when an interview was created in January 2023, the candidate may have had a
different job function or primary skill than they do today. A PIT join ensures the fact
table reflects the **historical state** at the time of the event:

```sql
LEFT JOIN dim_candidate dc
    ON dc.id = i.candidate_id
   AND interview_created_at >= dc.valid_from_datetime
   AND interview_created_at <  dc.valid_to_datetime
```

This is only possible because the staging layer retains all historical versions (SCD2).
{% enddocs %}
