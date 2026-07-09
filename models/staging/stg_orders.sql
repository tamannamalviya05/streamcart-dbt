{{ config(
    materialized='incremental',
    unique_key='event_id',
    incremental_strategy='merge',
    on_schema_change='sync_all_columns'
) }}

with raw_orders AS (

    SELECT
        PARSE_JSON(data, 'd') AS json_data,
        _loaded_at

    FROM {{ source('raw_streamcart', 'raw_orders') }} 

    {% if is_incremental() %}

    WHERE _loaded_at >
    (
        SELECT MAX(_loaded_at)
        FROM {{ this }}
    )

    {% endif %}
),

deduplicated AS (

    SELECT
        json_data,
        _loaded_at,

        TRIM(json_data:event_id::STRING) AS event_id,

        ROW_NUMBER() OVER (
            PARTITION BY TRIM(json_data:event_id::STRING)
            ORDER BY _loaded_at DESC
        ) AS rn

    FROM raw_orders
),

latest_events AS (

    SELECT *
    FROM deduplicated
    WHERE rn = 1
      AND LOWER(TRIM(json_data:metadata.is_test_event::STRING)) <> 'true'

),

flattened_items AS (

    SELECT
        l.json_data,
        l._loaded_at,
        f.value AS item
    FROM latest_events l,
    LATERAL FLATTEN(
        INPUT => l.json_data:order.items
    ) f

),
order_lines AS (

    SELECT
        _loaded_at,
        event_id,
        event_type,
        occurred_at,
        customer_id,
        customer_name,
        email,
        phone,
        customer_tier,
        city,
        country_code,
        order_id,
        channel,
        order_date,
        currency_code,
        order_total,
        product_id,
        quantity,
        unit_price,
        discount_pct,
        payment_method,
        payment_status,

        quantity * unit_price AS gross_amount

    FROM (
        SELECT
        
        /* Event */
        _loaded_at,
        TRIM(json_data:event_id::STRING) AS event_id,

        LOWER(TRIM(json_data:event_type::STRING)) AS event_type,

        TRY_TO_TIMESTAMP(
            json_data:occurred_at::STRING,
            'DD/MM/YYYY HH24:MI:SS'
        ) AS occurred_at,

        /* Customer */

        TRIM(json_data:customer.id::STRING) AS customer_id,

        {% if target.name == 'prod' %}
        INITCAP(TRIM(json_data:customer.name::STRING)) AS customer_name,
        {% else %}
        'Customer_' || TRIM(json_data:customer.id::STRING) AS customer_name,
        {% endif %}

        
        LOWER(TRIM(json_data:customer.email::STRING)) AS email,

        /*LOWER(TRIM(json_data:customer.email::STRING)) AS email,*/

        RIGHT(
            REGEXP_REPLACE(
                json_data:customer.phone::STRING,
                '[^0-9]',
                ''
            ),
            10
        ) AS phone,

        COALESCE(
            INITCAP(LOWER(json_data:customer.tier::STRING)),
            'Standard'
        ) AS customer_tier,

        INITCAP(
            LOWER(
                json_data:customer.address.city::STRING
            )
        ) AS city,

        UPPER(
            TRIM(
                json_data:customer.address.country::STRING
            )
        ) AS country_code,

        /* Order */

        TRIM(json_data:order.order_id::STRING) AS order_id,

        LOWER(
            REPLACE(
                TRIM(json_data:order.channel::STRING),
                ' ',
                '_'
            )
        ) AS channel,

        {{ parse_date_flexible(
        "json_data:order.placed_at::STRING",
        "DD/MM/YYYY",
        "YYYY-MM-DD"
        ) }} AS order_date,

        UPPER(
            TRIM(
                json_data:order.currency::STRING
            )
        ) AS currency_code,

        {{ clean_amount("json_data:order.total_amount::STRING") }} AS order_total,

        /* Item */

        TRIM(
            item:product_id::STRING
        ) AS product_id,

        CASE
            WHEN TRY_TO_NUMBER(item:qty::STRING) IS NULL THEN NULL
            WHEN TRY_TO_NUMBER(item:qty::STRING) = 0 THEN NULL
            ELSE TRY_TO_NUMBER(item:qty::STRING)
        END AS quantity,

        {{ clean_amount("item:unit_price::STRING") }} AS unit_price,

        CASE
            WHEN TRY_TO_DOUBLE(item:discount_pct::STRING) > 60
                THEN NULL
            ELSE TRY_TO_DOUBLE(item:discount_pct::STRING)
        END AS discount_pct,

        /* Payment */

        LOWER(
            REPLACE(
                json_data:order.payment.method::STRING,
                ' ',
                '_'
            )
        ) AS payment_method,

        LOWER(
            json_data:order.payment.status::STRING
        ) AS payment_status,

        /* Metrics */
        (
            CASE
                WHEN TRY_TO_NUMBER(item:qty::STRING) IS NULL THEN NULL
                WHEN TRY_TO_NUMBER(item:qty::STRING) = 0 THEN NULL
                ELSE TRY_TO_NUMBER(item:qty::STRING)
            END
            *
            {{ clean_amount("item:unit_price::STRING") }}
        ) AS gross_amount,

        (
            (
                CASE
                    WHEN TRY_TO_NUMBER(item:qty::STRING) IS NULL THEN NULL
                    WHEN TRY_TO_NUMBER(item:qty::STRING) = 0 THEN NULL
                    ELSE TRY_TO_NUMBER(item:qty::STRING)
                END
                *
                {{ clean_amount("item:unit_price::STRING") }}
            )
            *
            (
                1 - COALESCE(
                    CASE
                        WHEN TRY_TO_DOUBLE(item:discount_pct::STRING) > 60
                            THEN NULL
                        ELSE TRY_TO_DOUBLE(item:discount_pct::STRING)
                    END,
                    0
                ) / 100
            )
        ) AS net_amount

    FROM flattened_items
    )
)
SELECT

    *,
    {{ safe_net_amount('gross_amount', 'discount_pct') }} AS net_amount

FROM order_lines