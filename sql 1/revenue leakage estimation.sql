--gross potential revenue
SELECT
    ROUND(SUM(cart_value), 2) AS gross_potential_revenue
FROM cart_items;
--actual realised revenue
SELECT
    ROUND(SUM(amount), 2) AS realized_revenue
FROM payments
WHERE payment_status = 'success';
--revenue lost due to payment failure
SELECT
    ROUND(SUM(amount), 2) AS payment_failure_loss
FROM payments
WHERE payment_status = 'failed';
--revenue recovered via payment retries
WITH recovered_payments AS (
    SELECT DISTINCT payment_id
    FROM payment_attempts
    WHERE attempt_status = 'success'
      AND attempt_number > 1
)

SELECT
    ROUND(SUM(p.amount), 2) AS recovered_revenue
FROM payments p
JOIN recovered_payments r
    ON p.payment_id = r.payment_id


--net payment leakage
SELECT 
    ROUND(
        (SELECT SUM(amount) FROM payments WHERE payment_status = 'failed') - 
        COALESCE((SELECT SUM(amount) FROM payments WHERE payment_id IN (
            SELECT DISTINCT payment_id FROM payment_attempts 
            WHERE attempt_status = 'success' AND attempt_number > 1
        )), 0), 
    2) AS net_payment_leakage;


--order leakage and cart abandment leakage
SELECT
    ROUND(SUM(o.order_value), 2) AS order_leakage
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id
WHERE o.order_status != 'cancelled'
  AND p.payment_status != 'success';
SELECT
    ROUND(SUM(c.cart_value), 2) AS cart_abandonment_leakage
FROM cart_items c
LEFT JOIN orders o ON c.user_id = o.user_id
WHERE o.order_id IS NULL


--leakage by payment method
SELECT
    payment_method,
    ROUND(SUM(CASE WHEN payment_status = 'failed' THEN amount ELSE 0 END), 2) AS leaked_revenue
FROM payments
GROUP BY payment_method
ORDER BY leaked_revenue DESC

--leakage by failure reason
SELECT
    failure_reason,
    ROUND(SUM(amount), 2) AS revenue_lost
FROM payments
WHERE payment_status = 'failed'
GROUP BY failure_reason
ORDER BY revenue_lost DESC;

--leakage concentration
SELECT
    failure_reason,
    ROUND(
        100.0 * SUM(amount) / SUM(SUM(amount)) OVER (), 2
    ) AS pct_contribution
FROM payments
WHERE payment_status = 'failed'
GROUP BY failure_reason
ORDER BY pct_contribution DESC;

