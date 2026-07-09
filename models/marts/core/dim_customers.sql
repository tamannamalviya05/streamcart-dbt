SELECT

d.customer_id,
d.customer_name,
d.email,
d.phone,
d.customer_tier,
d.city,
d.country_code,

cc.country_name,
cc.region,
cc.currency_default,
cc.tax_rate_pct,

d.total_orders,
d.total_gross_revenue,
d.total_net_revenue,

ROUND(
    {{ dbt_utils.safe_divide(
        "d.total_net_revenue",
        "d.total_orders"
    ) }},
    2
) AS avg_order_value,

d.customer_segment,
d.days_since_last_order

FROM {{ ref('int_customer_summary') }} as d
LEFT JOIN {{ ref('country_config') }} cc
    ON d.country_code = cc.country_code
