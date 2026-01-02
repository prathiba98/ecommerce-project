create database ecommerce
use ecommerce

select top 1 * from [dbo].[users]
select top 1 * from [dbo].[sessions]
select top 1 * from [dbo].[product_views]
select top 1 * from [dbo].[payments]
select top 1 * from [dbo].[payment_attempts]
select top 1 * from [dbo].[orders]
select top 1 * from [dbo].[cart_items]

--data cleaning and checking

SELECT 'users' AS table_name, COUNT(*) AS row_count FROM users
UNION ALL
SELECT 'sessions', COUNT(*) FROM sessions
UNION ALL
SELECT 'product_views', COUNT(*) FROM product_views
UNION ALL
SELECT 'cart_items', COUNT(*) FROM cart_items
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'payment_attempts', COUNT(*) FROM payment_attempts

--checking primary keys
-- Payment Attempts
SELECT COUNT(*) - COUNT(DISTINCT attempt_id) AS duplicate_attempt_ids
FROM payment_attempts-- Users
SELECT COUNT(*) - COUNT(DISTINCT user_id) AS duplicate_user_ids
FROM users;

-- Orders
SELECT COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_ids
FROM orders;

-- Payments
SELECT COUNT(*) - COUNT(DISTINCT payment_id) AS duplicate_payment_ids
FROM payments;
;

--checking null values
SELECT
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
    SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END) AS null_signup_date
FROM users;
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN order_value IS NULL THEN 1 ELSE 0 END) AS null_order_value
FROM orders;

--get sessions without users
SELECT s.session_id
FROM sessions s
LEFT JOIN users u ON s.user_id = u.user_id
WHERE u.user_id IS NULL;

--cleaning up ghost orders
SELECT o.order_id
FROM orders o
LEFT JOIN users u ON o.user_id = u.user_id
WHERE u.user_id IS NULL;

--find ghost revenue
SELECT p.payment_id
FROM payments p
LEFT JOIN orders o ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

--unlinked payment attempt
SELECT pa.attempt_id
FROM payment_attempts pa
LEFT JOIN payments p ON pa.payment_id = p.payment_id
WHERE p.payment_id IS NULL;

--logical checks
SELECT payment_id, payment_status, failure_reason
FROM payments
WHERE payment_status = 'success'
  AND failure_reason IS NOT NULL;

SELECT payment_id
FROM payments
WHERE payment_status = 'failed'
  AND failure_reason IS NULL;

--order and payments mismatch
SELECT
    o.order_id,
    o.order_status,
    p.payment_status
FROM orders o
JOIN payments p ON o.order_id = p.order_id
WHERE o.order_status = 'failed'
  AND p.payment_status = 'success';

--order and payment time check
SELECT
    o.order_id,
    o.order_time,
    p.payment_time
FROM orders o
JOIN payments p ON o.order_id = p.order_id
WHERE p.payment_time < o.order_time;

--checking invalid monetary values
SELECT *
FROM orders
WHERE order_value <= 0;
SELECT *
FROM payments
WHERE amount <= 0;

--checking double charging
 SELECT
    payment_id,
    MAX(attempt_number) AS max_attempts,
    SUM(CASE WHEN attempt_status = 'success' THEN 1 ELSE 0 END) AS success_attempts
FROM payment_attempts
GROUP BY payment_id
HAVING SUM(CASE WHEN attempt_status = 'success' THEN 1 ELSE 0 END)>1








