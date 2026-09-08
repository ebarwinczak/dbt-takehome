{{
    config(
        materialized='view'
    )
}}

SELECT DISTINCT
    listing_id,
    host_id,
    host_verification

FROM {{ ref('stg_listings') }}

CROSS JOIN UNNEST(
    host_verifications_list
) AS t(host_verification)

WHERE host_verifications_list IS NOT NULL
