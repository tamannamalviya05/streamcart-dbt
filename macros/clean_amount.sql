{% macro clean_amount(col) %}

TRY_TO_DECIMAL(
    TRIM(
        REPLACE(
            REPLACE(
                {{ col }},
                '$',
                ''
            ),
            ',',
            ''
        )
    ),
    12,
    2
)

{% endmacro %}