with pageviews as (

    select * from {{ref('jitsu_events')}}

    {% if is_incremental() %}
    where user_anonymous_id in (
    select distinct events.user_anonymous_id
    from {{ref('jitsu_events')}} events, (select max(_timestamp) as ts from {{ this }}) maxts
    where {{ dbt_utils.datediff('events._timestamp', 'maxts.ts', 'minute') }} <= {{ var('jitsu_sessionization_trailing_window') }}
    )
    {% endif %}

    ),


numbered as (

    select

    *,

    row_number() over (
    partition by user_anonymous_id
    order by _timestamp
    ) as pageview_number

    from pageviews

    ),

lagged as (

    --This CTE is responsible for simply grabbing the last value of `_timestamp`.
    --We'll use this downstream to do timestamp math--it's how we determine the
    --period of inactivity.

    select

    *,
    {{ lag('_timestamp', 'user_anonymous_id', 'pageview_number') }}  as previous_timestamp

    from numbered

    ),

diffed as (

    --This CTE simply calculates `period_of_inactivity`.

    select
    *,
    {{ dbt_utils.datediff('previous_timestamp', '_timestamp', 'second') }} as period_of_inactivity
    from lagged

    ),

    new_sessions as (

    --This CTE calculates a single 1/0 field--if the period of inactivity prior
    --to this page view was greater than 30 minutes, the value is 1, otherwise
    --it's 0. We'll use this to calculate the user's session #.

    select
    *,
    case
    when period_of_inactivity <= {{var('jitsu_session_inactivity_cutoff')}} then 0
    else 1
    end as new_session
    from diffed

    ),

session_numbers as (

    --This CTE calculates a user's session (1, 2, 3) number from `new_session`.
    --This single field is the entire point of the entire prior series of
    --calculations.

    select

    *,

    sum(new_session) over (
    partition by user_anonymous_id
    order by pageview_number
    rows between unbounded preceding and current row
    ) as session_number

    from new_sessions

    ),

session_ids as (

    --This CTE assigns a globally unique session id based on the combination of
    --`user_anonymous_id` and `session_number`.

    select

    {{dbt_utils.star(ref('jitsu_events'))}},
    pageview_number,
    {{dbt_utils.surrogate_key(['user_anonymous_id', 'session_number'])}} as session_id

    from session_numbers

    )

select * from session_ids
