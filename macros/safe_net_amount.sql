{% macro safe_net_amount(gross, disc) %}

(
    {{ gross }}
    *
    (
        1 - COALESCE({{ disc }}, 0) / 100
    )
)

{% endmacro %}