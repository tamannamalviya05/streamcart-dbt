{{ config(
    materialized='incremental',
    unique_key='order_line_key',
    incremental_strategy='merge',
    on_schema_change='sync_all_columns',
    cluster_by=['order_date'],

    post_hook=[

        "ALTER TABLE {{ this }} CLUSTER BY (order_date)",   

        "{% if target.name == 'prod' %}
            GRANT SELECT ON {{ this }} TO ROLE prod_reader
         {% endif %}"

    ]
 )}}


SELECT

    {{ dbt_utils.generate_surrogate_key(
        ['f.order_id','f.product_id']
    ) }} AS order_line_key,

    f.event_id,
    f.order_id,
    f.customer_id,
    f.product_id,
    f.order_date,
    f.channel,

    cm.channel_label,
    cm.channel_group,
    cm.is_digital,

    f.currency_code,
    f.payment_method,
    f.payment_status,

    f.quantity,
    f.unit_price,
    f.discount_pct,
    f.gross_amount,
    f.net_amount,

    f.customer_name,
    f.email,
    f.phone,
    f.customer_tier,
    f.city,
    f.country_code,

    f.product_name,
    f.category,
    f.sub_category,
    f.brand,
    f.margin_pct,
    f.is_low_stock,

    {% if var('show_margin', false) %}

    f.margin_pct
    *
    (
        1 - COALESCE(f.discount_pct,0)/100
    ) AS effective_margin_pct,

    {% endif %}

    f.qty_on_hand,
    f.reorder_level,
    f.warehouse_code

FROM {{ ref('int_orders_enriched') }} as f
LEFT JOIN {{ ref('channel_mapping') }} cm
    ON f.channel = cm.channel_code

{% if is_incremental() %}

WHERE f.order_date >
(
    SELECT COALESCE(MAX(order_date), '1900-01-01'::DATE)
    FROM {{ this }}
)

{% endif %}

/*SELECT 
    {{ dbt_utils.generate_surrogate_key(
        ['f.order_id','f.product_id']
    ) }} AS order_line_key,

    event_id,
    order_id,
    customer_id,
    product_id,
    order_date,
    channel,
    currency_code,
    payment_method,
    payment_status,

    quantity,
    unit_price,
    discount_pct,
    gross_amount,
    net_amount,

    customer_name,
    email,
    phone,
    customer_tier,
    city,
    country_code,

    product_name,
    category,
    sub_category,
    brand,
    margin_pct,
    is_low_stock,

    {% if var('show_margin', false) %}

    margin_pct
    *
    (
        1 - COALESCE(discount_pct,0)/100
    ) AS effective_margin_pct,

    {% endif %}

    qty_on_hand,
    reorder_level,
    warehouse_code

FROM {{ ref('int_orders_enriched') }} as f
{% if is_incremental() %}

WHERE f.order_date >
(
    SELECT MAX(order_date)
    FROM {{ this }}
)

{% endif %} */