{% macro generate_row_key(cols_list) %}

MD5(
    CONCAT_WS(
        '|',
        {% for col in cols_list %}
            COALESCE(CAST({{ col }} AS STRING), '')
            {% if not loop.last %},{% endif %}
        {% endfor %}
    )
)

{% endmacro %}