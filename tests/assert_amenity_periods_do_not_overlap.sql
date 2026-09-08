WITH validity_periods AS (

    SELECT
        listing_id,
        dbt_valid_from,
        dbt_valid_to,

        LAG(dbt_valid_to) OVER (
            PARTITION BY listing_id
            ORDER BY dbt_valid_from
        ) AS previous_valid_to

    FROM {{ ref('int_amenities_changelog_wide') }}

)

SELECT *

FROM validity_periods

WHERE dbt_valid_from <= previous_valid_to
