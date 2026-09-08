{{
    config(
        materialized = 'table',
        partition_by = 'dbt_valid_from',
        cluster_by = 'listing_id'
    )
}}
/*
For snapshotting amenities changes we have multiple options: 
1. we could create a dbt snapshot based off of amenities in the listings csv 
2. we can use the amenities_changelog csv, operating under the assumption that THAT table is set up as a snapshot already
    and that it just needs some light cleaning 
I am moving forward w option 2, as creating an actual snapshot table in dbt would assign "valid from" to today's date
(9/7/2026) which would be problematic for when we join to CALENDAr; we also wouldn't have history 
*/
SELECT
    -- create unique key for each listing amenity snapshot; use hash function 
    MD5(
        CAST(listing_id AS VARCHAR)
        || '|'
        || CAST(change_at AS VARCHAR)
    ) AS snapshot_key,
    listing_id,
    amenities_list,
    change_at AS dbt_valid_from,
    -- generate "dbt_valid_to" field 
    COALESCE(
        LEAD(change_at) OVER (
            PARTITION BY listing_id
            ORDER BY change_at
        ) - INTERVAL 1 DAY,
        CURRENT_DATE() -- set dbt_valid_to to current_date if null 
    ) AS dbt_valid_to 

FROM {{ ref('stg_amenities_changelog') }}
