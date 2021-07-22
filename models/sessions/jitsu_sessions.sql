{{ config(
    unique_key = 'session_id',
    sort = 'session_start_timestamp',
    dist = 'session_id',
    )}}

{% set partition_by = "partition by session_id" %}

{% set window_clause = "
    partition by session_id
    order by pageview_number
    rows between unbounded preceding and unbounded following
    " %}

{% set first_values = {
    'utm_source' : 'utm_source',
    'utm_medium' : 'utm_medium',
    'utm_campaign' : 'utm_campaign',
    'url' : 'first_url',
    'doc_host' : 'first_doc_host',
    'doc_path' : 'first_doc_path',
    'doc_search' : 'first_doc_search',
    'referer' : 'referer',
    'parsed_ua_os_family' : 'parsed_ua_os_family',
    } %}

{% set last_values = {
    'url' : 'last_url',
    'doc_host' : 'last_doc_host',
    'doc_path' : 'last_doc_path',
    'doc_search' : 'last_doc_search'
    } %}

{% for col in var('jitsu_pass_through_columns') %}
    {% do first_values.update({col: 'first_' ~ col}) %}
    {% do last_values.update({col: 'last_' ~ col}) %}
{% endfor %}

with pageviews_sessionized as (

    select events.* from {{ref('jitsu_events_plus_session_id')}} events
    {% if is_incremental() %}
    , (select max(session_start_timestamp) as ts from {{ this }}) maxts
    where {{ dbt_utils.datediff('events._timestamp', 'maxts.ts', 'minute') }} <= {{ var('jitsu_sessionization_trailing_window') }}
    {% endif %}

),

referrer_mapping as (

    select * from {{ ref('referrer_mapping') }}

),

agg as (

    select distinct

        session_id,
        user_anonymous_id,
        last_value(coalesce(user_anonymous_id, user_id, user_email)) over ({{window_clause}}) as blended_user_id,
        min(_timestamp) over ( {{partition_by}} ) as session_start_timestamp,
        max(_timestamp) over ( {{partition_by}} ) as session_end_timestamp,
        count(*) over ( {{partition_by}} ) as pageviews,

        {% for (key, value) in first_values.items() %}
        first_value({{key}}) over ({{window_clause}}) as {{value}},
        {% endfor %}

        {% for (key, value) in last_values.items() %}
        last_value({{key}}) over ({{window_clause}}) as {{value}}{% if not loop.last %},{% endif %}
        {% endfor %}

    from pageviews_sessionized

),

diffs as (

    select

        *,

        {{ dbt_utils.datediff('session_start_timestamp', 'session_end_timestamp', 'second') }} as duration_in_s

    from agg

),

tiers as (

    select

        *,

        case
            when duration_in_s between 0 and 9 then '0s to 9s'
            when duration_in_s between 10 and 29 then '10s to 29s'
            when duration_in_s between 30 and 59 then '30s to 59s'
            when duration_in_s > 59 then '60s or more'
            else null
        end as duration_in_s_tier

    from diffs

),

mapped as (

    select
        tiers.*,
        referrer_mapping.medium as referrer_medium,
        referrer_mapping.source as referrer_source

    from tiers

    left join referrer_mapping on REPLACE({{ dbt_utils.get_url_host('tiers.referer') }},'www.','') =  referrer_mapping.host

)

select * from mapped
