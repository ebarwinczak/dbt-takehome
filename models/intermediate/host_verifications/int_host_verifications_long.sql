{{
    config(
        materialized='view'
    )
}}
-- view bc quite lightweight transformation, small dataset 
-- want as a view and not ephermal bc having this object saved can be helpful for debugging its downstream model 
SELECT DISTINCT
    listing_id,
    host_id,
    host_verification

FROM {{ ref('stg_listings') }}

CROSS JOIN UNNEST(
    host_verifications_list
) AS t(host_verification)

WHERE host_verifications_list IS NOT NULL
