SELECT *

FROM {{ ref('stg_listings') }}

WHERE
    -- listing must accommodate at least one guest
    accommodates_count < 1

    -- property counts cannot be negative
    OR bedrooms_count < 0
    OR beds_count < 0
    OR bathroom_count < 0

    -- price and review metrics cannot be negative
    OR price < 0
    OR review_count < 0
    OR review_scores_rating < 0