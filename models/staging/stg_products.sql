WITH raw_products AS (

    SELECT
         PARSE_JSON(data, 'd') AS json_data,
        _loaded_at
    FROM {{ source('raw_streamcart', 'raw_products') }}

),

deduplicated AS (

    SELECT
        json_data,
        _loaded_at,
        TRIM(json_data:product_id::STRING) AS product_id,

        ROW_NUMBER() OVER (
            PARTITION BY TRIM(json_data:product_id::STRING)
            ORDER BY _loaded_at DESC
        ) AS rn

    FROM raw_products

)

SELECT

    /* Product Information */

    TRIM(json_data:product_id::STRING) AS product_id,

    TRIM(json_data:name::STRING) AS product_name,

    INITCAP(
        LOWER(
            TRIM(json_data:category::STRING)
        )
    ) AS category,

    LOWER(
        TRIM(json_data:sub_category::STRING)
    ) AS sub_category,

    INITCAP(
        LOWER(
            TRIM(json_data:brand::STRING)
        )
    ) AS brand,

    {{ standardise_boolean("json_data:is_available::STRING") }} AS is_available,

    ARRAY_TO_STRING(json_data:tags, ', ') AS tags,

    /* Specifications */

    TRY_TO_DOUBLE(
        json_data:specs.weight_kg::STRING
    ) AS weight_kg,

    TRY_TO_NUMBER(
        json_data:specs.warranty_yr::STRING
    ) AS warranty_years,

    /* Pricing */

    TRY_TO_DOUBLE(
        json_data:pricing.cost_price::STRING
    ) AS cost_price,

    TRY_TO_DOUBLE(
        json_data:pricing.list_price::STRING
    ) AS list_price,

    /* Inventory */

    TRY_TO_NUMBER(
        json_data:stock.qty_on_hand::STRING
    ) AS qty_on_hand,

    TRY_TO_NUMBER(
        json_data:stock.reorder_lvl::STRING
    ) AS reorder_level,

    UPPER(
        TRIM(
            json_data:stock.warehouse::STRING
        )
    ) AS warehouse_code,

    /* Derived Columns */

    ROUND(
        (
            TRY_TO_DOUBLE(json_data:pricing.list_price::STRING)
            -
            TRY_TO_DOUBLE(json_data:pricing.cost_price::STRING)
        )
        /
        NULLIF(
            TRY_TO_DOUBLE(json_data:pricing.list_price::STRING),
            0
        ) * 100,
        2
    ) AS margin_pct,

    CASE
        WHEN TRY_TO_NUMBER(json_data:stock.qty_on_hand::STRING)
             <=
             TRY_TO_NUMBER(json_data:stock.reorder_lvl::STRING)
        THEN TRUE
        ELSE FALSE
    END AS is_low_stock

FROM deduplicated

WHERE rn = 1