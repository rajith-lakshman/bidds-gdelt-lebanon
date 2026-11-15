{% macro in_window(col='_PARTITIONTIME') %}
    {{ col }} >= timestamp('{{ var("start_date") }} 00:00:00')
    and {{ col }} <= timestamp('{{ var("end_date") }} 23:59:59')
{% endmacro %}
