{{
    config(
        materialized='view'
    )
}}

SELECT DISTINCT
    listing_id,
    amenity,
    dbt_valid_from,
    dbt_valid_to

FROM {{ ref('snapshot_amenities_changelog') }}

-- convert each amenities list into one row per amenity
-- while preserving the listing's historical validity period
CROSS JOIN UNNEST(
    amenities_list
) AS t(amenity)

WHERE amenities_list IS NOT NULL
