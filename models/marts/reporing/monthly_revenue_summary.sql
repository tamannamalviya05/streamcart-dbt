WITH monthly_summary AS (

    SELECT

        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,

        COUNT(DISTINCT CASE
            WHEN payment_status = 'success'
            THEN order_id
        END) AS total_orders,

        SUM(CASE
            WHEN payment_status = 'success'
            THEN gross_amount
            ELSE 0
        END) AS total_gross_revenue,

        SUM(CASE
            WHEN payment_status = 'success'
            THEN net_amount
            ELSE 0
        END) AS total_net_revenue,

        SUM(CASE
            WHEN payment_status = 'success'
            THEN gross_amount - net_amount
            ELSE 0
        END) AS total_discount_given,

        AVG(discount_pct) AS avg_discount_pct

    FROM {{ ref('fct_orders') }}

    GROUP BY
        YEAR(order_date),
        MONTH(order_date)

),

category_rank AS (

    SELECT

        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,

        category,

        SUM(net_amount) AS revenue,

        ROW_NUMBER() OVER(
            PARTITION BY YEAR(order_date), MONTH(order_date)
            ORDER BY SUM(net_amount) DESC
        ) AS rn

    FROM {{ ref('fct_orders') }}

    WHERE payment_status='success'

    GROUP BY
        YEAR(order_date),
        MONTH(order_date),
        category

),

channel_rank AS (

    SELECT

        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,

        channel,

        COUNT(DISTINCT order_id) AS order_count,

        ROW_NUMBER() OVER(
            PARTITION BY YEAR(order_date), MONTH(order_date)
            ORDER BY COUNT(DISTINCT order_id) DESC
        ) AS rn

    FROM {{ ref('fct_orders') }}

    GROUP BY
        YEAR(order_date),
        MONTH(order_date),
        channel

)

SELECT

    m.*,

    c.category AS top_category,

    ch.channel AS top_channel

FROM monthly_summary m

LEFT JOIN category_rank c

ON m.order_year = c.order_year
AND m.order_month = c.order_month
AND c.rn = 1

LEFT JOIN channel_rank ch

ON m.order_year = ch.order_year
AND m.order_month = ch.order_month
AND ch.rn = 1