SELECT *

FROM {{ ref('stg_listings') }}

WHERE
    first_review_date IS NOT NULL
    AND last_review_date IS NOT NULL
    AND last_review_date < first_review_date
    