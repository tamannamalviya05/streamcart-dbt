{% snapshot customer_tier_snapshot %}
{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='_loaded_at'
    )
}}
WITH latest_customer AS (
    SELECT
        TRIM(PARSE_JSON(data):customer.id::STRING) AS customer_id,
        INITCAP(
            LOWER(
                TRIM(PARSE_JSON(data):customer.tier::STRING)
            )
        ) AS customer_tier,
        INITCAP(
            LOWER(
                TRIM(PARSE_JSON(data):customer.address.city::STRING)
            )
        ) AS city,
        _loaded_at,
        ROW_NUMBER() OVER(

            PARTITION BY
            TRIM(PARSE_JSON(data):customer.id::STRING)

            ORDER BY _loaded_at DESC

        ) rn
    FROM {{ source('raw_streamcart','raw_orders') }}
)
SELECT
customer_id,
customer_tier,
city,
_loaded_at
FROM latest_customer
WHERE rn=1

{% endsnapshot %}