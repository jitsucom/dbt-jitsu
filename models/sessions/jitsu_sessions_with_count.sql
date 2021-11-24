select * ,
       row_number() over (
            partition by blended_user_id
            order by session_start_timestamp
            )
            as sessions_count
from {{ref('jitsu_sessions')}}
