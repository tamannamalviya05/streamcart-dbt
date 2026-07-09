SELECT *

FROM {{ ref('stg_orders') }}

WHERE discount_pct > 60
AND discount_pct IS NOT NULL