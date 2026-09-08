SELECT
    listing_id,
    calendar_date,
    COUNT(*) AS row_count

FROM {{ ref('mart_listings_daily') }}

GROUP BY
    listing_id,
    calendar_date

HAVING COUNT(*) > 1
