{{
    config(
        materialized = 'table',
        partition_by = 'calendar_date',
        cluster_by = 'listing_id'
    )
}}

SELECT
    listing_id,
    calendar_date,
    -- listing_id for given date is available only if all rows say available:
    BOOL_AND(is_available) AS is_available,
    -- count reservations, shouldn't be more than 1 though: 
    COUNT(DISTINCT reservation_id) AS reservation_count,
    -- keep reservation IDs for reference and put in array just in case more than one exists:
    ARRAY_AGG(
        DISTINCT reservation_id
    ) FILTER (
        WHERE reservation_id IS NOT NULL
    ) AS reservation_ids,
    -- assuming price, min and max nights should be the same per listing per day, so can take max: 
    MAX(nightly_price) AS nightly_price,
    MAX(minimum_nights) AS minimum_nights,
    MAX(maximum_nights) AS maximum_nights

FROM {{ ref('stg_calendar') }}

GROUP BY
    listing_id,
    calendar_date
    