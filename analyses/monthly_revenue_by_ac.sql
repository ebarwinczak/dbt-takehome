/*
Question 1: Monthly Revenue by Air Conditioning

Find the total revenue and percentage of revenue by month,
segmented by whether or not air conditioning exists on the listing.

Revenue is defined as the nightly price for reserved nights.
*/
WITH monthly_rev_by_ac AS (
    SELECT 
        DATE_TRUNC('month', calendar_date) AS revenue_month,
        air_conditioning,
        SUM(CASE WHEN reservation_count > 0 THEN nightly_price ELSE 0 END) AS total_revenue,

    FROM {{ ref('mart_listings_daily') }}
    GROUP BY 1, 2
)

SELECT
    revenue_month,
    air_conditioning,
    total_revenue,
    SUM(total_revenue) OVER(PARTITION BY revenue_month) AS monthly_total_revenue, 
    ROUND((total_revenue/SUM(total_revenue) OVER(PARTITION BY revenue_month))*100, 2) AS perc_monthly_total_rev 

FROM monthly_rev_by_ac
ORDER BY revenue_month, air_conditioning