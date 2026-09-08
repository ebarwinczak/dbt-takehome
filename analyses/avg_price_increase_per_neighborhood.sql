/* Question 2: host_neighborhood Pricing 
Write a query to find the average price increase for each host_neighborhood from July 12th 2021 to July 11th 2022.
*/

-- Step 1: get price increase for each LISTING in each host_neighborhood between the two dates
-- assumption: if the listing is present in one date and not the other, we will exclude it.
-- assumption 2: if for whatever reason the listing id has changed host_neighborhoods, we will exclude it.
WITH july_2021 AS (
    SELECT 
        host_neighborhood,
        listing_id,
        nightly_price AS price_july_2021 

    FROM {{ ref('mart_listings_daily') }} 
    WHERE calendar_date = '2021-07-12'
),

july_2022 AS (
    SELECT  
        host_neighborhood,
        listing_id,
        nightly_price AS price_july_2022

    FROM {{ ref('mart_listings_daily') }} 
    WHERE calendar_date = '2022-07-11'
),

price_diff AS (
    SELECT 
        j21.host_neighborhood,
        j21.listing_id,
        j21.price_july_2021,
        j22.price_july_2022,
        j22.price_july_2022 - j21.price_july_2021 AS price_diff
    
    FROM july_2021 AS j21
    INNER JOIN july_2022 AS j22
        ON j21.host_neighborhood = j22.host_neighborhood
            AND j21.listing_id = j22.listing_id
)

-- Step 2: average price_diff per host_neighborhood
SELECT 
    host_neighborhood,
    AVG(price_diff) AS avg_price_change

FROM price_diff 
GROUP BY host_neighborhood
ORDER BY host_neighborhood
