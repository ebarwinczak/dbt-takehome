{{
    config(
        materialized='table'
    )
}}
-- flag: could potentially make this incremental but would need to deal w potential for new cols being added
-- could set append_new_columns for on_schema_change but new col values will be null for historical data, but we could fix this downstream
-- data is small for this use case and a full rebuild is quick / cheap, so keeping as a table 
-- get distinct list of amenities from int_amenities_standardized; these will become columns 
-- could partition by dbt_valid_from and cluster by listing_id if data was larger 
{% set amenities_query %}

    SELECT DISTINCT amenity
    FROM {{ ref('int_amenities_changelog_standardized') }}
    WHERE amenity IS NOT NULL
    ORDER BY amenity

{% endset %}
-- execute the amenities_query and store it in amenity_results 
-- this will  return the distinct list of amenities 
{% set amenity_results = run_query(amenities_query) %}

-- take the distinct values of amenities stored in amenity_results (it only has one column)
-- save these values in amenity_columns var (which will be a list of our distinct values)
{% if execute %}
    {% set amenity_columns = amenity_results.columns[0].values() %}
{% else %}
    {% set amenity_columns = [] %} -- for when dbt is parsing 
{% endif %}

-- final output: for each listing_id, flag if it has each possible amenity (as separate cols)
SELECT
    listing_id,
    dbt_valid_from,
    dbt_valid_to,
    -- list of amenities to generate as cols in wide table; macro loops through this list to generate the cols
    {{ pivot_boolean_columns(
        column='amenity',
        values=amenity_columns 
    ) }}

FROM {{ ref('int_amenities_changelog_standardized') }}
GROUP BY 
    listing_id,
    dbt_valid_from,
    dbt_valid_to
    