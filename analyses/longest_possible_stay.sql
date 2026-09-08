/* Question 3: 
Write a query to determine the longest possible stay duration for rental listings that include both a lockbox and first aid kit
 in their amenities, considering both listing availability windows and maximum stay limits set by property owners.
*/
-- Step 1: get only available days for listings with first aid kit and a lockbox, and also include set max nights in this 
WITH available AS (
    SELECT 
        calendar_date,
        listing_id,
        maximum_nights 

    FROM {{ ref('mart_listings_daily') }}
    WHERE 
        is_available = TRUE 
        AND first_aid_kit = TRUE 
        AND lockbox = TRUE 
),

-- Step 2: flag when a new availability window is about to start: 
new_window AS (
    SELECT
        *,
        CASE 
            WHEN LAG(calendar_date) OVER(PARTITION BY listing_id ORDER BY calendar_date) = calendar_date - INTERVAL 1 DAY 
            THEN 0
            ELSE 1 
        END AS new_window_flag  

    FROM available 
),

-- Step 3: assign window groups: 
window_groups AS (
    SELECT 
        calendar_date,
        listing_id,
        maximum_nights,
        SUM(new_window_flag) OVER(PARTITION BY listing_id ORDER BY calendar_date ROWS UNBOUNDED PRECEDING) AS availability_window
    
    FROM new_window 
),
/*visual example for reference: 
calendar_date | new_window_flag | availability_window
--------------|-----------------|--------------------
Jan 1         | 1               | 1
Jan 2         | 0               | 1
Jan 3         | 0               | 1
Jan 6         | 1               | 2
Jan 7         | 0               | 2
Jan 8         | 0               | 2
*/ 

-- Step 4: just in case max nights changes within a listing's availability window, I'm making the assumption that
    -- we want whatever max nights was on the first night of the availability window 
get_max_nights_first_val AS (
    SELECT
        listing_id,
        availability_window,
        maximum_nights,
        ROW_NUMBER() OVER(PARTITION BY listing_id, availability_window ORDER BY calendar_date) AS list_avail_window_rownum
     
    FROM window_groups
    QUALIFY ROW_NUMBER() OVER(PARTITION BY listing_id, availability_window ORDER BY calendar_date) = 1
),


-- Step 5: for each availability_window group, get the first and last day (min and max cal date) 
    -- and count(*) to get number of days; we don't really need first and last day but good to have as reference
 
get_available_range AS (
    SELECT
        listing_id,
        availability_window,
        MIN(calendar_date) AS available_from,
        MAX(calendar_date) AS available_to,
        COUNT(*) AS available_days 
     
     FROM window_groups
     GROUP BY 
        listing_id,
        availability_window
),
-- Step 6: join to get_available_range and get_max_nights_first_val so we have goth 
joined_range_and_max AS (
    SELECT 
        rng.*,
        max.maximum_nights

    FROM get_available_range AS rng 
    INNER JOIN get_max_nights_first_val AS max 
        ON rng.listing_id = max.listing_id
            AND rng.availability_window = max.availability_window
)
-- Step 7: final select - we want to now know for each listing_id, what's the longest possible stay given max nights and available days
SELECT
    listing_id,
    available_from,
    available_to,
    available_days,
    maximum_nights,
    LEAST(
        available_days,
        maximum_nights
    ) AS longest_possible_stay_days

FROM joined_range_and_max
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY listing_id -- ignoring availability_window now! 
    ORDER BY
        LEAST(available_days, maximum_nights) DESC,
        available_from -- only necessary if there is a tie 
) = 1

ORDER BY longest_possible_stay_days DESC
