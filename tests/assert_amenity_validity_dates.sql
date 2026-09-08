SELECT *

FROM {{ ref('int_amenities_changelog_wide') }}

WHERE dbt_valid_to < dbt_valid_from
