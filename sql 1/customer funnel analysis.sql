WITH funnel_base AS (
    SELECT
        u.user_id,

        -- Stage 1: Visit
        CASE WHEN s.session_id IS NOT NULL THEN 1 ELSE 0 END AS visited,

        -- Stage 2: Product View
        CASE WHEN pv.view_id IS NOT NULL THEN 1 ELSE 0 END AS viewed_product,

        -- Stage 3: Add to Cart
        CASE WHEN c.cart_id IS NOT NULL THEN 1 ELSE 0 END AS added_to_cart,

        -- Stage 4: Order Created
        CASE WHEN o.order_id IS NOT NULL THEN 1 ELSE 0 END AS ordered,

        -- Stage 5: Payment Success
        CASE WHEN p.payment_status = 'success' THEN 1 ELSE 0 END AS payment_success

    FROM users u
    LEFT JOIN sessions s
        ON u.user_id = s.user_id
    LEFT JOIN product_views pv
        ON s.session_id = pv.session_id
    LEFT JOIN cart_items c
        ON u.user_id = c.user_id
    LEFT JOIN orders o
        ON u.user_id = o.user_id
    LEFT JOIN payments p
        ON o.order_id = p.order_id
)
--funnel drop off analysis
SELECT
    'Visit to View' AS stage,
    SUM(visited) - SUM(viewed_product) AS users_dropped
FROM funnel_base

UNION ALL

SELECT
    'View to Cart',
    SUM(viewed_product) - SUM(added_to_cart)
FROM funnel_base

UNION ALL

SELECT
    'Cart to Order',
    SUM(added_to_cart) - SUM(ordered)
FROM funnel_base

UNION ALL

SELECT
    'Order to Payment',
    SUM(ordered) - SUM(payment_success)
FROM funnel_base;

--funnel conversion rates
SELECT
    ROUND(100.0 * SUM(viewed_product) / NULLIF(SUM(visited), 0), 2) AS visit_to_view_pct,
    ROUND(100.0 * SUM(added_to_cart) / NULLIF(SUM(viewed_product), 0), 2) AS view_to_cart_pct,
    ROUND(100.0 * SUM(ordered) / NULLIF(SUM(added_to_cart), 0), 2) AS cart_to_order_pct,
    ROUND(100.0 * SUM(payment_success) / NULLIF(SUM(ordered), 0), 2) AS order_to_payment_pct
FROM funnel_base;

--funnel counts
SELECT 
    SUM(visited) AS total_visits,
    SUM(viewed_product) AS total_views,
    SUM(added_to_cart) AS total_add_to_carts,
    SUM(ordered) AS total_orders,
    SUM(payment_success) AS total_success_payments
FROM funnel_base;


--funnel by device type
WITH device_funnel AS (
    SELECT
        u.device_type,
        u.user_id,
        CASE WHEN s.session_id IS NOT NULL THEN 1 ELSE 0 END AS visited,
        CASE WHEN pv.view_id IS NOT NULL THEN 1 ELSE 0 END AS viewed,
        CASE WHEN c.cart_id IS NOT NULL THEN 1 ELSE 0 END AS cart,
        CASE WHEN o.order_id IS NOT NULL THEN 1 ELSE 0 END AS ordered,
        CASE WHEN p.payment_status = 'success' THEN 1 ELSE 0 END AS paid
    FROM users u
    LEFT JOIN sessions s ON u.user_id = s.user_id
    LEFT JOIN product_views pv ON s.session_id = pv.session_id
    LEFT JOIN cart_items c ON u.user_id = c.user_id
    LEFT JOIN orders o ON u.user_id = o.user_id
    LEFT JOIN payments p ON o.order_id = p.order_id
)

SELECT
    device_type,
    COUNT(DISTINCT user_id) AS users,
    SUM(paid) AS successful_payments,
    ROUND(100.0 * SUM(paid) / NULLIF(COUNT(DISTINCT user_id), 0), 2) AS overall_conversion_pct
FROM device_funnel
GROUP BY device_type;

--funnel by traffic source
SELECT
    s.traffic_source,
    COUNT(DISTINCT u.user_id) AS users,
    SUM(CASE WHEN p.payment_status = 'success' THEN 1 ELSE 0 END) AS paid_users,
    ROUND(
        100.0 * SUM(CASE WHEN p.payment_status = 'success' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT u.user_id), 0), 2
    ) AS conversion_pct
FROM users u
JOIN sessions s ON u.user_id = s.user_id
LEFT JOIN orders o ON u.user_id = o.user_id
LEFT JOIN payments p ON o.order_id = p.order_id
GROUP BY s.traffic_source;
