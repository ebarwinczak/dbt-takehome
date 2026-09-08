{{
    config(
        materialized='view'
    )
}}

WITH initial_cleaning AS (
    SELECT 
        *, -- pull in all raw cols for now 
        -- let's use our clean_string macro on the ID column, just in case there are scenarios where a blank consists of more than one space: 
        {{ clean_string('ID') }} AS listing_id, -- doing this in this CTE bc we will filter out NULL listing_ids in final select 
        STR_SPLIT(COALESCE({{ clean_string('HOST_LOCATION') }}, ''), ', ') AS host_location_parts 
        
    FROM {{ ref('LISTINGS') }}
)

SELECT
    CAST(listing_id AS INTEGER) AS listing_id,
    {{ clean_string('NAME') }} AS listing_name,
    HOST_ID AS host_id,
    {{ clean_string('HOST_NAME') }} AS host_name,
    CAST(HOST_SINCE AS DATE) AS host_since, -- converting timestamp to date bc all timeestamps at 00
    -- preserve original value just so we can trace if needed: 
    {{ clean_string('HOST_LOCATION') }} AS host_location,
    -- break locations out by city, state, country
    CASE
        WHEN ARRAY_LENGTH(host_location_parts) = 3
        THEN host_location_parts[1]
        ELSE NULL
    END AS host_city,
    CASE
        WHEN ARRAY_LENGTH(host_location_parts) = 3
        THEN host_location_parts[2]
        -- source sometimes only provides a state
        WHEN  UPPER({{ clean_string('HOST_LOCATION') }}) = 'MASSACHUSETTS'
        THEN 'Massachusetts'
        ELSE NULL
    END AS host_state,
    CASE
        WHEN ARRAY_LENGTH(host_location_parts) = 3
        THEN host_location_parts[3]
        WHEN UPPER({{ clean_string('HOST_LOCATION') }}) IN ('US', 'UNITED STATES')
        THEN 'United States'
        -- impute value for rows with only "Massachusetts" since these are obviously in the US
        WHEN  UPPER({{ clean_string('HOST_LOCATION') }}) = 'MASSACHUSETTS'
        THEN 'United States'
        ELSE NULL
    END AS host_country,
    {{ clean_string('NEIGHBORHOOD') }} AS host_neighborhood,
    {{ clean_string('PROPERTY_TYPE') }} AS property_type,
    CASE
        WHEN UPPER(ROOM_TYPE) LIKE '%ENTIRE%' THEN TRUE
        ELSE FALSE
    END AS is_entire_property,
    CASE
        WHEN UPPER(ROOM_TYPE) LIKE '%PRIVATE%' THEN TRUE
        ELSE FALSE
    END AS is_private_room,
    ACCOMMODATES AS accommodates_count,
    CAST(
        REGEXP_EXTRACT(
            BATHROOMS_TEXT,
            '([0-9]+[.]?[0-9]*)'
        ) AS DOUBLE
    ) AS bathroom_count,
    BEDROOMS AS bedrooms_count,
    BEDS AS beds_count,
    CAST(
        REGEXP_REPLACE(PRICE, '[$,]', '', 'g')
        AS DOUBLE
    ) AS price,
    NUMBER_OF_REVIEWS AS review_count,
    CAST(FIRST_REVIEW AS DATE) AS first_review_date,
    CAST(LAST_REVIEW AS DATE) AS last_review_date,
    REVIEW_SCORES_RATING AS review_scores_rating, -- I'm assuming this is an average but I'm leaving the name the same 
    -- host_verifications in as VARCHAR
    -- we want to convert it to a list so we can create cols in downstream model  
    FROM_JSON(
        HOST_VERIFICATIONS,
        '["VARCHAR"]'
    ) AS host_verifications_list
    -- not including amenities here, as it's handled in amenites_changelog models and will be joined with listings downstream

FROM initial_cleaning
WHERE listing_id IS NOT NULL 
