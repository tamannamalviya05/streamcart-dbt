{% macro standardise_boolean(col) %}

    CASE
        WHEN LOWER(TRIM({{col}}))
             IN ('1', 'yes', 'true', 'y')
            THEN TRUE
        ELSE FALSE
    END 

{% endmacro %}