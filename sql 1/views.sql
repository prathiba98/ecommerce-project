--1.executive summary
--are we making money ? where are we losing it
--1a.executive_kpis
CREATE VIEW executive_kpis AS
SELECT
    SUM(CASE WHEN payment_status = 'success' THEN amount ELSE 0 END) AS realized_revenue,
    SUM(CASE WHEN payment_status = 'failed' THEN amount ELSE 0 END) AS payment_failure_loss,
    COUNT(CASE WHEN payment_status = 'failed' THEN 1 END) * 100.0 / COUNT(*) AS payment_failure_rate
FROM payments;

SELECT * FROM executive_kpis

--1b.retry recovery
CREATE VIEW retry_recovery AS
SELECT
    SUM(p.amount) AS recovered_revenue
FROM payments p
JOIN payment_attempts pa
    ON p.payment_id = pa.payment_id
WHERE pa.attempt_number > 1
  AND pa.attempt_status = 'success';

  SELECT * FROM retry_recovery

--1c.net revenue leakage
 CREATE VIEW net_revenue_leakage AS
SELECT
    e.payment_failure_loss - r.recovered_revenue AS net_revenue_leakage
FROM executive_kpis e
CROSS JOIN retry_recovery r;

SELECT * FROM net_revenue_leakage

select top 1 * from product_views
select top 1 * from cart_items
select top 1 * from orders
select top 1 * from payments 
select top 1 * from sessions
select top 1 * from users
select top 1 * from payment_attempts
select top 1 * from support_tickets
--2.funnel analysis
--where exactly are customers dropping off
CREATE VIEW funnel_summary AS (
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

SELECT * FROM funnel_summary

--3.payment failure analysis
--3a.payment failure summary
CREATE VIEW payment_failures_summary AS
SELECT
    payment_method,
    COUNT(*) AS failed_payments,
    SUM(amount) AS revenue_lost
FROM payments
WHERE payment_status = 'failed'
GROUP BY payment_method;

SELECT * FROM payment_failures_summary


--3b.failure reason analysis
CREATE VIEW failure_reason_analysis AS
SELECT
    failure_reason,
    COUNT(*) AS failed_attempts,
    SUM(amount) AS revenue_lost
FROM payments
WHERE payment_status = 'failed'
GROUP BY failure_reason;

select * from failure_reason_analysis


--3c. failure by bank
CREATE VIEW failure_by_bank AS
SELECT
    bank,
    COUNT(*) AS failed_transactions
FROM payments
WHERE payment_status = 'failed'
GROUP BY bank;

select * from failure_by_bank


--4. retry and recovery analysis
--do retry actually recover revenue
--4a.retry attempts summary
CREATE VIEW retry_attempts_summary AS
SELECT
    attempt_number,
    COUNT(*) AS total_attempts,
    COUNT(CASE WHEN attempt_status = 'success' THEN 1 END) AS successful_attempts
FROM payment_attempts
GROUP BY attempt_number;

select * from retry_attempts_summary


--4b.recovery by method
CREATE VIEW recovery_by_method AS
SELECT
    p.payment_method,
    SUM(p.amount) AS recovered_revenue
FROM payments p
JOIN payment_attempts pa
    ON p.payment_id = pa.payment_id
WHERE pa.attempt_status = 'success'
  AND pa.attempt_number > 1
GROUP BY p.payment_method;

select * from recovery_by_method


--5.revenue leakage by device
 CREATE VIEW leakage_by_device AS
SELECT
    u.device_type,
    COUNT(DISTINCT o.order_id) AS failed_orders,
    SUM(o.order_value) AS revenue_lost
FROM orders o
JOIN users u
    ON o.user_id = u.user_id
LEFT JOIN payments p
    ON o.order_id = p.order_id
WHERE p.payment_status <> 'success'
   OR p.payment_status IS NULL
GROUP BY u.device_type;

select * from leakage_by_device


 
