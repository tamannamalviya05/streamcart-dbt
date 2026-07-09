{% test valid_currency(model, column_name) %}

SELECT *

FROM {{ model }}

WHERE {{ column_name }}

NOT IN (

'INR',
'USD',
'GBP',
'AED',
'EUR'

)

{% endtest %}