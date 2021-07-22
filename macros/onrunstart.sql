{% macro onrunstart() %}
    {{ return(adapter.dispatch('onrunstart')()) }}
{% endmacro %}

{% macro default__onrunstart() %}
{% endmacro %}


{% macro clickhouse__onrunstart() %}
SET allow_experimental_window_functions = 1
{% endmacro %}

