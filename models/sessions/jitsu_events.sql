{{ config(
    materialized = 'view'
    )}}

select * from {{var('jitsu_events_table')}} where user_anonymous_id is not null