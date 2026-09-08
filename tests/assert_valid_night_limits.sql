SELECT *

FROM {{ ref('int_calendar_listing_daily') }}

WHERE
       minimum_nights < 0
    OR maximum_nights < 0
    OR minimum_nights > maximum_nights
    