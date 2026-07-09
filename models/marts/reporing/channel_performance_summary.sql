WITH channel_summary AS (

    SELECT

        order_date,
        channel,

        COUNT(DISTINCT order_id) AS total_orders,

        COUNT(DISTINCT CASE
            WHEN payment_status = 'success'
            THEN order_id
        END) AS successful_orders,

        COUNT(DISTINCT CASE
            WHEN payment_status = 'failed'
            THEN order_id
        END) AS cancelled_orders,

        SUM(gross_amount) AS total_gross_revenue,

        SUM(net_amount) AS total_net_revenue,

        ROUND(
            {{ dbt_utils.safe_divide(
                "SUM(net_amount)",
                "COUNT(DISTINCT order_id)"
            ) }},
            2
        ) AS avg_order_value

    FROM {{ ref('fct_orders') }}

    GROUP BY
        order_date,
        channel

),

payment_rank AS (

    SELECT

        order_date,
        channel,
        payment_method,

        COUNT(*) AS payment_count,

        ROW_NUMBER() OVER (

            PARTITION BY order_date, channel

            ORDER BY COUNT(*) DESC

        ) AS rn

    FROM {{ ref('fct_orders') }}

    GROUP BY

        order_date,
        channel,
        payment_method

)

SELECT

    c.order_date,

    c.channel,

    c.total_orders,

    c.successful_orders,

    c.cancelled_orders,

    ROUND(

        {{ dbt_utils.safe_divide(
            "successful_orders",
            "total_orders"
        ) }} * 100,

        2

    ) AS success_rate_pct,

    c.total_gross_revenue,

    c.total_net_revenue,

    c.avg_order_value,

    p.payment_method AS most_used_payment_method

FROM channel_summary c

LEFT JOIN payment_rank p

ON c.order_date = p.order_date
AND c.channel = p.channel
AND p.rn = 1