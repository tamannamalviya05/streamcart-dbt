SELECT *

FROM {{ ref('stg_orders') }}

WHERE order_date > CURRENT_DATE