{{
    config(
        materialized='table',
        cluster_by=['listing_id', 'host_id']
    )
}}

-- partitioning/clustering configs included to show how we could optimize querying but data is quite small so not necessary

SELECT
    -- listing identifiers:
    listings.listing_id,
    listings.listing_name,
    -- host information:
    listings.host_id,
    listings.host_name,
    listings.host_since,
    listings.host_location,
    listings.host_city,
    listings.host_state,
    listings.host_country,
    listings.host_neighborhood,
    -- property information:
    listings.property_type,
    listings.is_entire_property,
    listings.is_private_room,
    listings.accommodates_count,
    listings.bathroom_count,
    listings.bedrooms_count,
    listings.beds_count,
    -- pricing
    listings.price,
    -- reviews
    listings.review_count,
    listings.first_review_date,
    listings.last_review_date,
    listings.review_scores_rating,
    -- dynamically generated host verification columns:
    verifications.* EXCLUDE (listing_id) -- we're doing a select * for this bc new values could be introduced and we want to select all possible columns

FROM {{ ref('stg_listings') }} AS listings

LEFT JOIN {{ ref('int_host_verifications_wide') }} AS verifications
    ON listings.listing_id = verifications.listing_id
    