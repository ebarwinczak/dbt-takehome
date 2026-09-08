{{
    config(
        materialized='table',
        partition_by = 'calendar_date',
        cluster_by = 'listing_id'
    )
}}

SELECT
    calendar.listing_id,
    calendar.calendar_date,
    -- calendar/reservation metrics:
    calendar.is_available,
    calendar.reservation_count,
    calendar.reservation_ids,
    calendar.nightly_price,
    calendar.minimum_nights,
    calendar.maximum_nights,
    -- listing dimensions: 
    listings.listing_name,
    listings.host_id,
    listings.host_name,
    listings.host_since,
    listings.host_location,
    listings.host_city,
    listings.host_state,
    listings.host_country,
    listings.host_neighborhood,
    listings.property_type,
    listings.is_entire_property,
    listings.is_private_room,
    listings.accommodates_count,
    listings.bathroom_count,
    listings.bedrooms_count,
    listings.beds_count,
    listings.price AS listing_price,
    listings.review_count,
    listings.first_review_date,
    listings.last_review_date,
    listings.review_scores_rating,
    -- dynamic host verification columns (needs to be a select * with an EXCLUDE for all the columns we just selected): 
    listings.* EXCLUDE (
        listing_id,
        listing_name,
        host_id,
        host_name,
        host_since,
        host_location,
        host_city,
        host_state,
        host_country,
        host_neighborhood,
        property_type,
        is_entire_property,
        is_private_room,
        accommodates_count,
        bathroom_count,
        bedrooms_count,
        beds_count,
        price,
        review_count,
        first_review_date,
        last_review_date,
        review_scores_rating
    ),
    -- amenity date ranges from changelog: 
    amenities.dbt_valid_from AS amenities_valid_from,
    amenities.dbt_valid_to AS amenities_valid_to,
    -- dynamic amenity columns (neesd to be a select * with an EXCLUDE for all the columns we just selected):
    amenities.* EXCLUDE (
        listing_id,
        dbt_valid_from,
        dbt_valid_to
    )

FROM {{ ref('int_calendar_listing_daily') }} AS calendar

LEFT JOIN {{ ref('int_listings') }} AS listings
    ON calendar.listing_id = listings.listing_id

LEFT JOIN {{ ref('int_amenities_changelog_wide') }} AS amenities
    ON calendar.listing_id = amenities.listing_id
    AND calendar.calendar_date BETWEEN amenities.dbt_valid_from AND amenities.dbt_valid_to
    