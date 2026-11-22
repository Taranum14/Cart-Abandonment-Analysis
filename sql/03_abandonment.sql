-- A cart item = one product added to cart in one session.
-- Two definitions of "abandoned", because the data shows people sometimes
-- cart in one session and buy in a later one:
--   abandoned_strict : never bought that product in the SAME session
--   abandoned_final  : the same user never bought that product at or after
--                      the cart time, anywhere in the dataset period
-- Report abandoned_final as the main number and abandoned_strict as the
-- upper bound. Note: carts made near the end of the period may still convert
-- after the data stops, so abandoned_final is slightly overstated too.
CREATE OR REPLACE TABLE cart_outcomes AS
WITH carts AS (
    SELECT user_session, product_id,
           ANY_VALUE(user_id)  AS user_id,
           ANY_VALUE(category) AS category,
           ANY_VALUE(brand)    AS brand,
           MAX(price)          AS price,
           MIN(event_time)     AS first_cart_time
    FROM events
    WHERE event_type = 'cart'
    GROUP BY user_session, product_id
),
buys_session AS (
    SELECT DISTINCT user_session, product_id
    FROM events
    WHERE event_type = 'purchase'
),
buys_user AS (
    SELECT user_id, product_id, MAX(event_time) AS last_purchase_time
    FROM events
    WHERE event_type = 'purchase'
    GROUP BY user_id, product_id
)
SELECT
    c.*,
    CASE WHEN bs.product_id IS NULL THEN 1 ELSE 0 END AS abandoned_strict,
    CASE WHEN bu.last_purchase_time IS NULL
           OR bu.last_purchase_time < c.first_cart_time THEN 1 ELSE 0 END AS abandoned_final
FROM carts c
LEFT JOIN buys_session bs
       ON c.user_session = bs.user_session AND c.product_id = bs.product_id
LEFT JOIN buys_user bu
       ON c.user_id = bu.user_id AND c.product_id = bu.product_id;

-- Headline numbers
SELECT
    COUNT(*)                                                       AS cart_items,
    SUM(abandoned_strict)                                          AS abandoned_strict_items,
    SUM(abandoned_final)                                           AS abandoned_final_items,
    ROUND(100.0 * SUM(abandoned_strict) / COUNT(*), 2)             AS abandon_rate_strict_pct,
    ROUND(100.0 * SUM(abandoned_final) / COUNT(*), 2)              AS abandon_rate_final_pct,
    ROUND(SUM(CASE WHEN abandoned_final = 1 THEN price END), 0)    AS revenue_at_risk_final
FROM cart_outcomes;

-- Worst categories by revenue at risk
SELECT
    category,
    COUNT(*)                                                       AS cart_items,
    ROUND(100.0 * AVG(abandoned_final), 2)                         AS abandon_rate_final_pct,
    ROUND(SUM(CASE WHEN abandoned_final = 1 THEN price END), 0)    AS revenue_at_risk
FROM cart_outcomes
GROUP BY category
ORDER BY revenue_at_risk DESC
LIMIT 10;

-- Abandonment by hour of day
SELECT
    EXTRACT(hour FROM first_cart_time)       AS hour,
    ROUND(100.0 * AVG(abandoned_final), 2)   AS abandon_rate_final_pct,
    COUNT(*)                                 AS cart_items
FROM cart_outcomes
GROUP BY 1
ORDER BY 1;

-- Abandonment by price band
SELECT
    CASE WHEN price < 20 THEN '1. <20'
         WHEN price < 100 THEN '2. 20-100'
         WHEN price < 300 THEN '3. 100-300'
         ELSE '4. 300+' END                  AS price_band,
    ROUND(100.0 * AVG(abandoned_final), 2)   AS abandon_rate_final_pct,
    COUNT(*)                                 AS cart_items
FROM cart_outcomes
GROUP BY 1
ORDER BY 1;
