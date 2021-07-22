### jitsu_events

{% docs jitsu_events %}

View for jitsu events that will be used for session calculation.
Some filtering or renaming may be done here

{% enddocs %}


### jitsu_events_plus_session_id

{% docs jitsu_events_plus_session_id %}

This model assign `session_id` to pageview events.
Consequent events belongs to the same session 
as long as interval between two event is no longer than `jitsu_session_inactivity_cutoff`

{% enddocs %}

### jitsu_sessions

{% docs jitsu_sessions %}

This model aggregates session based on `session_id` column added in `jitsu_events_plus_session_id` step.

{% enddocs %}


### jitsu_sessions

{% docs jitsu_sessions_with_count %}

Create the view that adds sessions_count column

{% enddocs %}
