{{ config(materialized='ephemeral') }}

SELECT

    o.*,

    p.product_name,
    p.category,
    p.sub_category,
    p.brand,
    p.margin_pct,
    p.is_low_stock,
    p.qty_on_hand,
    p.reorder_level,
    p.warehouse_code,

    CASE
        WHEN o.discount_pct > 0 THEN TRUE
        ELSE FALSE
    END AS is_discounted

FROM {{ ref('stg_orders') }} o

LEFT JOIN {{ ref('stg_products') }} p
    ON o.product_id = p.product_id

WHERE o.event_type = 'order_placed'