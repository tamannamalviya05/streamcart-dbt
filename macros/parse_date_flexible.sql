{% macro parse_date_flexible(col, fmt1, fmt2) %}

CASE
    WHEN {{ col }} LIKE '__/__/____'
        THEN TRY_TO_DATE({{ col }}, '{{ fmt1 }}')
    ELSE
        TRY_TO_DATE({{ col }}, '{{ fmt2 }}')
END

{% endmacro %}