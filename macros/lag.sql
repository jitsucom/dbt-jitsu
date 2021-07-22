{% macro lag(param, partitionBy, orderBy) %}
    {{ return(adapter.dispatch('lag')(param, partitionBy, orderBy)) }}
{% endmacro %}

{% macro default__lag(param, partitionBy, orderBy, rowOrRange) %}
lag({{param}}) over (
    partition by {{partitionBy}}
    order by {{orderBy}}
    )
{% endmacro %}


{% macro clickhouse__lag(param, partitionBy, orderBy, rowOrRange) %}
any({{param}}) over (
    partition by {{partitionBy}}
    order by {{orderBy}}
    rows between 1 preceding and 1 preceding
    )
{% endmacro %}

