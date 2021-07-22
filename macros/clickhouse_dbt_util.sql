{% macro clickhouse__hash(field) %}
    hex(MD5(cast({{field}} as {{dbt_utils.type_string()}})))
{% endmacro %}

{% macro clickhouse__type_string() %}
    varchar
{% endmacro %}

{% macro clickhouse__datediff(first_date, second_date, datepart) %}
dateDiff('{{ datepart }}',{{ first_date }},{{ second_date }})
{% endmacro %}

{% macro clickhouse__split_part(string_text, delimiter_text, part_number) %}

    splitByString(
        {{ delimiter_text }},
        {{ string_text }}
        )[{{ part_number }}]

{% endmacro %}