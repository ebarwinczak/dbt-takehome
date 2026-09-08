SELECT *

FROM {{ ref('int_calendar_listing_daily') }}

WHERE reservation_count > 1
