{% set categories = [
    'Electronics',
    'Apparel',
    'Home Goods'
] %}

SELECT

customer_id,

{% for cat in categories %}

SUM(
    CASE
        WHEN category='{{ cat }}'
        THEN net_amount
        ELSE 0
    END
) AS {{ cat|lower|replace(' ','_') }}_revenue

{% if not loop.last %},{% endif %}

{% endfor %}

FROM {{ ref('fct_orders') }}

GROUP BY customer_id