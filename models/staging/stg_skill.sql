-- DQ Fix: 8 source rows have null name and are excluded here
{{ staging_model('skills', 'id', filter_condition='name is not null') }}
