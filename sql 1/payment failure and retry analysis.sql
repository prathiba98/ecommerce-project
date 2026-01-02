SELECT COUNT(*) FROM payments
--detecting failures
SELECT
    payment_status,
    COUNT(*) AS transactions,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_share
FROM payments
GROUP BY payment_status;

--failure rate by payment method
SELECT
    payment_method,
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END) AS failed_payments,
    ROUND(
        100.0 * SUM(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS failure_rate_pct
FROM payments
GROUP BY payment_method
ORDER BY failure_rate_pct DESC;

--failure reason distribution
SELECT
    failure_reason,
    COUNT(*) AS failed_transactions,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2
    ) AS pct_of_failures
FROM payments
WHERE payment_status = 'failed'
GROUP BY failure_reason
ORDER BY failed_transactions DESC

--revenue lost due to failed payments
SELECT
    ROUND(SUM(amount), 2) AS revenue_lost_due_to_failed_payment
FROM payments
WHERE payment_status = 'failed'

--retry stats
SELECT
    payment_id,
    MAX(attempt_number) AS total_attempts,
    MAX(CASE WHEN attempt_status = 'success' THEN 1 ELSE 0 END) AS recovered
FROM payment_attempts
GROUP BY payment_id;
--retry success rate
WITH retry_summary AS (
    SELECT
        payment_id,
        COUNT(*) AS attempts,
        SUM(CASE WHEN attempt_status = 'success' THEN 1 ELSE 0 END) AS success_count
    FROM payment_attempts
    GROUP BY payment_id
)

SELECT
    COUNT(*) AS total_payments,
    SUM(CASE WHEN success_count > 0 THEN 1 ELSE 0 END) AS recovered_payments,
    ROUND(
        100.0 * SUM(CASE WHEN success_count > 0 THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS retry_recovery_pct
FROM retry_summary;

--revenue recovered due to retry
WITH recovered_payments AS (
    SELECT DISTINCT
        pa.payment_id
    FROM payment_attempts pa
    WHERE pa.attempt_status = 'success'
      AND pa.attempt_number > 1
)

SELECT
    ROUND(SUM(p.amount), 2) AS revenue_recovered
FROM payments p
JOIN recovered_payments rp
    ON p.payment_id = rp.payment_id;

--attempts needed for success
SELECT
    attempt_number,
    COUNT(*) AS successful_payments
FROM payment_attempts
WHERE attempt_status = 'success'
GROUP BY attempt_number
ORDER BY attempt_number;
SELECT TOP 1 * FROM PAYMENTS

--failure rate by bank
SELECT
    bank,
    COUNT(*) AS total_payments,
    SUM(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END) AS failed_payments,
    ROUND(
        100.0 * SUM(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS failure_rate_pct
FROM payments P
GROUP BY bank
ORDER BY failure_rate_pct DESC



