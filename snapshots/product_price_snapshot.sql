{% snapshot product_price_snapshot %}
{{
    config(
        target_schema='snapshots',
        unique_key='product_id',
        strategy='check',
        check_cols=['list_price','is_available']
    )
}}
WITH latest_products AS (
    SELECT
        TRIM(PARSE_JSON(data,'d'):product_id::STRING) AS product_id,
        TRY_TO_DOUBLE(
            PARSE_JSON(data,'d'):pricing.list_price::STRING
        ) AS list_price,
        CASE
            WHEN LOWER(TRIM(PARSE_JSON(data,'d'):is_available::STRING))
                IN ('1','yes','true')
            THEN TRUE
            ELSE FALSE
        END AS is_available,
        _loaded_at,
        ROW_NUMBER() OVER (
            PARTITION BY
                TRIM(PARSE_JSON(data,'d'):product_id::STRING)
            ORDER BY _loaded_at DESC
        ) AS rn
    FROM {{ source('raw_streamcart','raw_products') }}
)
SELECT
    product_id,
    list_price,
    is_available
FROM latest_products
WHERE rn = 1
{% endsnapshot %}