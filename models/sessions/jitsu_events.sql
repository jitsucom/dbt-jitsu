{% if var('jitsu_events_table_filter') is defined %}
    select * from {{var('jitsu_events_table')}} where user_anonymous_id is not null and {{var('jitsu_events_table_filter')}}
{% else %}
    select * from {{var('jitsu_events_table')}} where user_anonymous_id is not null
{% endif %}

