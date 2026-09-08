{{
    config(
        materialized='view'
    )
}}

SELECT
    LISTING_ID AS listing_id,
    DATE AS calendar_date,
    CASE
        WHEN AVAILABLE = 't' THEN TRUE
        WHEN AVAILABLE = 'f' THEN FALSE
        ELSE NULL
    END AS is_available,
    CAST( NULLIF({{clean_string('RESERVATION_ID')}}, 'NULL') AS INTEGER) AS reservation_id,
    PRICE AS nightly_price,
    MINIMUM_NIGHTS AS minimum_nights,
    MAXIMUM_NIGHTS AS maximum_nights

FROM {{ ref('CALENDAR') }}

WHERE LISTING_ID IS NOT NULL
  AND DATE IS NOT NULL
  