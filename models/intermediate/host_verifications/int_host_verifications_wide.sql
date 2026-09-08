{{
    config(
        materialized='table'
    )
}}

{% set verifications_query %}

    SELECT DISTINCT host_verification
    FROM {{ ref('int_host_verifications_long') }}
    WHERE host_verification IS NOT NULL
    ORDER BY host_verification

{% endset %}

{% if execute %}
    {% set verification_results = run_query(verifications_query) %}
    {% set verification_columns = verification_results.columns[0].values() %}
{% else %}
    {% set verification_columns = [] %}
{% endif %}

SELECT
    listing_id,
    {{ pivot_boolean_columns(
        column='host_verification',
        values=verification_columns
    ) }}

FROM {{ ref('int_host_verifications_long') }}
GROUP BY listing_id
