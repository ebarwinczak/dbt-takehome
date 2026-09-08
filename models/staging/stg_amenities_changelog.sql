{{
    config(
        materialized='view'
    )
}}

SELECT
    LISTING_ID AS listing_id, -- in case there are blanks in the CSV
    CAST(CHANGE_AT AS TIMESTAMP) AS change_at,
    FROM_JSON(LOWER({{ clean_string('AMENITIES') }}), '["VARCHAR"]') AS amenities_list

FROM {{ ref('AMENITIES_CHANGELOG')}}
WHERE LISTING_ID IS NOT NULL 
