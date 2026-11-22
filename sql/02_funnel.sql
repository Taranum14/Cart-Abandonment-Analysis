-- Funnel by session: view -> cart -> purchase.
-- The cart-to-purchase rate uses only sessions that carted AND purchased,
-- so it can never exceed 100%. Sessions that purchased without a cart event
-- (cart made in an earlier session, or a direct buy) are counted separately.
WITH session_flags AS (
    SELECT
        user_session,
        MAX(CASE WHEN event_type = 'view'     THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_type = 'cart'     THEN 1 ELSE 0 END) AS carted,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY user_session
)
SELECT
    SUM(viewed)                                                    AS sessions_viewed,
    SUM(carted)                                                    AS sessions_carted,
    SUM(CASE WHEN carted = 1 AND purchased = 1 THEN 1 ELSE 0 END) AS carted_and_purchased,
    SUM(CASE WHEN carted = 0 AND purchased = 1 THEN 1 ELSE 0 END) AS purchased_without_cart,
    SUM(purchased)                                                 AS sessions_purchased_total,
    ROUND(100.0 * SUM(carted) / NULLIF(SUM(viewed), 0), 2)         AS view_to_cart_pct,
    ROUND(100.0 * SUM(CASE WHEN carted = 1 AND purchased = 1 THEN 1 ELSE 0 END)
          / NULLIF(SUM(carted), 0), 2)                             AS cart_to_purchase_pct
FROM session_flags;

-- Funnel by category (same strict logic)
WITH session_cat AS (
    SELECT
        category,
        user_session,
        MAX(CASE WHEN event_type = 'view'     THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_type = 'cart'     THEN 1 ELSE 0 END) AS carted,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY category, user_session
)
SELECT
    category,
    SUM(viewed)                                                    AS views,
    SUM(carted)                                                    AS carts,
    SUM(CASE WHEN carted = 1 AND purchased = 1 THEN 1 ELSE 0 END) AS carted_and_purchased,
    SUM(CASE WHEN carted = 0 AND purchased = 1 THEN 1 ELSE 0 END) AS purchased_without_cart,
    ROUND(100.0 * SUM(carted) / NULLIF(SUM(viewed), 0), 2)         AS view_to_cart_pct,
    ROUND(100.0 * SUM(CASE WHEN carted = 1 AND purchased = 1 THEN 1 ELSE 0 END)
          / NULLIF(SUM(carted), 0), 2)                             AS cart_to_purchase_pct
FROM session_cat
GROUP BY category
HAVING SUM(carted) > 1000
ORDER BY carts DESC;
