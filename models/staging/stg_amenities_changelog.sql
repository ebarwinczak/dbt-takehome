{{
    config(
        materialized='view'
    )
}}

SELECT
    CAST({{ clean_string('CAST(LISTING_ID AS VARCHAR)') }} AS INTEGER) AS listing_id, -- in case there are blanks in the CSV
    CAST(CHANGE_AT AS TIMESTAMP) AS change_at,
    FROM_JSON(LOWER({{ clean_string('AMENITIES') }}), '["VARCHAR"]') AS amenities_list

FROM {{ ref('AMENITIES_CHANGELOG')}}
WHERE {{ clean_string('CAST(LISTING_ID AS VARCHAR)') }} IS NOT NULL 
