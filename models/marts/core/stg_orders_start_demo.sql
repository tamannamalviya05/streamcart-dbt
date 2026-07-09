SELECT

{{ dbt_utils.star(
    from=source('raw_streamcart', 'raw_orders'),
    except=['_loaded_at', '_source']
) }}

FROM {{ source('raw_streamcart', 'raw_orders') }}