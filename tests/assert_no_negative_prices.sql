SELECT *

FROM {{ ref('stg_orders') }}

WHERE unit_price < 0
AND unit_price IS NOT NULL