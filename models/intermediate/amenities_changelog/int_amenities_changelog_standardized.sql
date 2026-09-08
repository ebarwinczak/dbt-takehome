{{
    config(
        materialized='view'
    )
}}
-- keeping this as a view since the standardization rules might change and there's not a lot of heavy computation happening here 
WITH standardized_amenities AS (
    SELECT
        listing_id,
        standardized_amenity,
        dbt_valid_from,
        dbt_valid_to

    FROM {{ ref('int_amenities_changelog_long') }}

    CROSS JOIN UNNEST(
    -- doing some light amenity categorization but ideally more cleaning and standardization could occur more upstream 
    -- we need to do a CROSS JOIN UNNEST for amenity rows where one string contains multiple amenities (for example "smart tv and cable tv")
    -- also flagging that we could make a macro to do this, but for now I think it's good to have visibility in-line of what's changing
        CASE
            -- HDTV + streaming services + cable:
            WHEN amenity LIKE '%hdtv%'
                 AND (
                     amenity LIKE '%netflix%'
                     OR amenity LIKE '%hbo%'
                     OR amenity LIKE '%amazon prime%'
                 )
                 AND amenity LIKE '%cable%'
            -- add 2 amenities for this row: 
            THEN [
                'smart tv',
                'cable tv'
            ]

            -- HDTV + streaming services, but no cable:
            WHEN amenity LIKE '%hdtv%'
                 AND (
                     amenity LIKE '%netflix%'
                     OR amenity LIKE '%hbo%'
                     OR amenity LIKE '%amazon prime%'
                 )
            THEN ['smart tv']

            -- anything mentioning standard cable:
            WHEN amenity LIKE '%standard cable%'
            THEN ['cable tv']

            -- shower essentials:  
            WHEN amenity LIKE '%body soap%' 
                OR amenity LIKE '%conditioner%' 
                OR amenity LIKE '%shampoo%' 
                OR amenity LIKE '%shower gel%'
            THEN ['shower essentials']

            -- cooking basics:
            WHEN amenity LIKE '%baking sheet%' 
            THEN ['cooking basics']

            -- coffee maker:
            WHEN amenity LIKE '%coffee machine%' 
            THEN ['coffee maker']

            -- keep everything else the same: 
            ELSE [amenity]

        END
    ) AS standardized(standardized_amenity)
)

SELECT
    listing_id,
    standardized_amenity AS amenity,
    dbt_valid_from,
    dbt_valid_to

FROM standardized_amenities
