{{ config(materialized='ephemeral') }}

SELECT
    customer_id,
    customer_name,
    email,
    phone,
    customer_tier,
    city,
    country_code,
    COUNT(DISTINCT CASE
        WHEN payment_status='success'
        THEN order_id
    END) AS total_orders,
    SUM(CASE
        WHEN payment_status='success'
        THEN gross_amount
    END) AS total_gross_revenue,
    SUM(CASE
        WHEN payment_status='success'
        THEN net_amount
    END) AS total_net_revenue,
    ROUND(
        {{ dbt_utils.safe_divide(
            "SUM(CASE WHEN payment_status='success' THEN net_amount END)",
            "COUNT(DISTINCT CASE WHEN payment_status='success' THEN order_id END)"
        ) }},
        2
    ) AS avg_order_value,
    DATEDIFF(
        day,
        MAX(order_date),
        CURRENT_DATE()
    ) AS days_since_last_order,
    CASE
        WHEN COUNT(DISTINCT order_id) >= 10 THEN 'Platinum'
        WHEN COUNT(DISTINCT order_id) >= 5 THEN 'Gold'
        WHEN COUNT(DISTINCT order_id) >= 2 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_segment
FROM {{ ref('int_orders_enriched') }}
GROUP BY
    customer_id,
    customer_name,
    email,
    phone,
    customer_tier,
    city,
    country_code