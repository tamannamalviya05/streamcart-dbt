WITH product_summary AS (

    SELECT

        product_id,
        product_name,
        category,
        sub_category,
        brand,
        margin_pct,
        is_low_stock,
        qty_on_hand,
        reorder_level,
        warehouse_code,

        SUM(
            CASE
                WHEN payment_status = 'success'
                THEN quantity
                ELSE 0
            END
        ) AS total_units_sold,

        SUM(
            CASE
                WHEN payment_status = 'success'
                THEN net_amount
                ELSE 0
            END
        ) AS total_net_revenue,

        AVG(discount_pct) AS avg_discount_pct

    FROM {{ ref('fct_orders') }}

    GROUP BY

        product_id,
        product_name,
        category,
        sub_category,
        brand,
        margin_pct,
        is_low_stock,
        qty_on_hand,
        reorder_level,
        warehouse_code

)

SELECT
    *,
    RANK() OVER (
        PARTITION BY category
        ORDER BY total_net_revenue DESC
    ) AS revenue_rank

FROM product_summary