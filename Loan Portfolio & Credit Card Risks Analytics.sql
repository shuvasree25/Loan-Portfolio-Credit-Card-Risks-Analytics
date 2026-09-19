CREATE TABLE customers
(
customer_id	INT PRIMARY KEY,
customer_name VARCHAR(100),	
age	INT,
income DECIMAL(10, 3),
employment_type VARCHAR(50),
credit_score INT,	
state VARCHAR(30)
);

SELECT * FROM customers

CREATE TABLE loans
(
loan_id INT PRIMARY KEY,
customer_id INT,
loan_type VARCHAR(100),
loan_amount	DECIMAL(10, 2),
outstanding_balance DECIMAL(10, 2),
interest_rate DECIMAL(10, 2),	
loan_status VARCHAR(100),
state VARCHAR(40),	
origination_date DATE,	
maturity_date DATE
);

SELECT * FROM loans;

CREATE TABLE payment
(
payment_id INT PRIMARY KEY,
loan_id INT,
payment_date DATE,	
scheduled_amount DECIMAL(10, 2),
actual_payment DECIMAL(10, 2),	
principal_paid DECIMAL(10, 2),	
interest_paid DECIMAL(10, 2),	
days_past_due INT,
payment_status VARCHAR(30)
);

SELECT * FROM payments;

CREATE TABLE collateral
(
collateral_id INT PRIMARY KEY,	
loan_id INT,
collateral_type VARCHAR(50),
collateral_value DECIMAL(10, 2),
valuation_date DATE
);

SELECT * FROM collateral;

-- Business Questions
-- What is the total loan portfolio?
SELECT
  ROUND(SUM(loan_amount)) AS total_loan_portfolio
FROM loans;
-- What is the total outstanding exposure?
SELECT 
  ROUND(SUM(outstanding_balance)) AS outstanding_exposure
FROM loans;
-- What percentage of the original portfolio remains outstanding?
SELECT 
  ROUND(SUM(outstanding_balance)) * 100.0 / 
  NULLIF(ROUND(SUM(loan_amount),0), 2)
  AS portfolio_outstanding
FROM loans;  
-- Which loan types contribute the most exposure?
SELECT 
  loan_type,
ROUND(SUM(outstanding_balance)) AS exposure
FROM loans
GROUP BY loan_type
ORDER BY exposure DESC;
-- Which US states have the highest loan exposure?
SELECT 
  state,
ROUND(SUM(outstanding_balance)) AS exposure
FROM loans
GROUP BY state
ORDER BY exposure DESC 
lIMIT 5;
-- What is the average loan size?
SELECT  
  ROUND(AVG(loan_amount)) AS average_loan_amount
FROM loans;
-- What is the weighted average interest rate?
SELECT
  ROUND(SUM(loan_amount * interest_rate)) /
  ROUND(NULLIF(SUM(loan_amount),0), 2
    ) AS weighted_avg_interest_rate
FROM loans;
-- What is the overall default rate?
SELECT
  ROUND(COUNT(*) FILTER (WHERE loan_status = 'Defaulted')
        * 100.0 / COUNT(*), 2
    ) AS default_rate
FROM loans;
-- Which loan type has the highest default rate?
SELECT 
  loan_type,
  ROUND(COUNT(*) FILTER (WHERE loan_status = 'Defaulted')
        * 100.0 / COUNT(*), 2
    ) AS default_rate
FROM loans
GROUP BY loan_type
ORDER BY default_rate;
-- Which state has the highest default exposure?
SELECT 
 state,
 ROUND(SUM(outstanding_balance)) AS default_exposure
FROM loans
WHERE loan_status = 'Defaulted'
GROUP BY state
ORDER BY default_exposure 
LIMIT 5;
-- Which credit-score segment has the highest default rate?
SELECT
  CASE 
   WHEN credit_score < 600 THEN 'Low'
   WHEN credit_score < 700 THEN 'Medium'
   ELSE 'High'
END AS credit_segment,
 ROUND(
        COUNT(*) FILTER (WHERE l.loan_status='Defaulted')
        * 100.0 / COUNT(*), 2
    ) AS default_rate
FROM customers c
INNER JOIN loans l
ON c.customer_id = l.customer_id
GROUP BY credit_segment
ORDER BY default_rate DESC;
-- How much outstanding exposure is tied to defaulted loans?
SELECT
 ROUND(SUM(outstanding_balance)) AS outstanding_exposure
FROM loans
WHERE loan_status = 'Defaulted';
-- Which customers have the highest credit exposure?
SELECT customer_id,
 ROUND(SUM(outstanding_balance)) AS highest_credit_exposure
FROM loans
GROUP BY customer_id
ORDER BY highest_credit_exposure DESC
LIMIT 5;
-- Which customers have multiple risky loans?
SELECT
    customer_id,
	COUNT(*) AS risky_loan_count 
FROM loans	
WHERE loan_status IN ('Delinquent', 'Defaulted')
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY risky_loan_count DESC
LIMIT 5;
-- What is the overall payment rate?
SELECT
ROUND
 (SUM(actual_payment) * 100.0 / 
 NULLIF(ROUND(SUM(scheduled_amount),0),2 
))
AS payment_rate
FROM payments;
-- What is the total scheduled payment amount?
SELECT 
 ROUND(SUM(scheduled_amount)) AS scheduled_payment_amount
FROM payments; 
-- What is the total actual payment amount
SELECT 
 ROUND(SUM(actual_payment)) AS actual_payment_amount
FROM payments; 
-- What is the total payment shortfall?
SELECT 
 ROUND(SUM(scheduled_amount - actual_payment)) AS payment_shortfall
FROM payments; 
-- Which loan types have the largest payment shortfall?
SELECT 
    l.loan_type,
	ROUND(SUM(p.scheduled_amount - p.actual_payment)) AS largest_payment_shortfall
FROM payments p
INNER JOIN loans l
ON p.loan_id = l.loan_id
GROUP BY l.loan_type
ORDER BY largest_payment_shortfall DESC;
-- Which loans have repeated late payments?
SELECT 
   loan_id,
    COUNT(*) FILTER (WHERE days_past_due > 0) AS late_payment_count
FROM payments
GROUP BY loan_id
HAVING COUNT(*) FILTER (WHERE days_past_due > 0) >= 2
ORDER BY late_payment_count DESC;
-- What is the average Days Past Due?
SELECT
   ROUND(AVG(days_past_due)) AS average_days_past_due
FROM payments
WHERE days_past_due > 0;
-- Which loans have severe delinquency?
SELECT
   loan_id,
   MAX(days_past_due) AS max_dpt
FROM payments
GROUP BY loan_id
HAVING MAX(days_past_due) >= 90
ORDER BY max_dpt DESC;
-- What is the total collateral value?
SELECT 
  ROUND(SUM(collateral_value)) AS total_collateral_value
FROM collateral;  
-- What is the portfolio collateral coverage ratio?
SELECT
 COALESCE(ROUND(SUM(c.collateral_value)))* 100.0 /
 NULLIF(ROUND(SUM(l.outstanding_balance),0),2
 )  AS collateral_coverage
FROM loans l
INNER JOIN collateral c
    ON l.loan_id = c.loan_id;	
-- What is the LTV for each loan?
SELECT
   l.loan_id,
   l.loan_type,
   l.outstanding_balance,
   c.collateral_value,
   ROUND(
       l.outstanding_balance * 100.0 /
       NULLIF(c.collateral_value,0),2
    ) AS ltv_pct
FROM loans l
LEFT JOIN collateral c
ON l.loan_id = c.loan_id;
-- Which loans have the highest LTV?
SELECT
   l.loan_id,
   l.loan_type,
   l.outstanding_balance,
   c.collateral_value,
   ROUND(
       l.outstanding_balance * 100.0 /
       NULLIF(c.collateral_value,0),2
    ) AS ltv_pct
FROM loans l
INNER JOIN collateral c
ON l.loan_id = c.loan_id
ORDER BY ltv_pct
LIMIT 10;
-- Which loans are under-collateralized?
SELECT
   l.loan_id,
   l.loan_type,
   l.outstanding_balance,
   c.collateral_value,
   l.outstanding_balance - c.collateral_value AS uncovered_exposure
FROM loans l
INNER JOIN collateral c
    ON l.loan_id = c.loan_id
WHERE l.outstanding_balance > c.collateral_value
ORDER BY uncovered_exposure DESC; 
-- Which states have the highest collateral shortfall?
SELECT
    l.state,
    SUM(
        GREATEST(l.outstanding_balance - c.collateral_value,0)
    ) AS collateral_shortfall
FROM loans l
INNER JOIN collateral c
    ON l.loan_id = c.loan_id
GROUP BY l.state
ORDER BY collateral_shortfall DESC
LIMIT 10;
-- Which loan types have the highest average LTV?
SELECT
    l.loan_type,
    ROUND(
        AVG(
            l.outstanding_balance * 100.0 /
            NULLIF(c.collateral_value,0)
        ),2
    ) AS average_ltv
FROM loans l
INNER JOIN collateral c
    ON l.loan_id = c.loan_id
GROUP BY l.loan_type
ORDER BY average_ltv DESC
LIMIT 10;
-- Which customers have the highest outstanding exposure?
SELECT
 c.customer_id,
 c.customer_name,
 SUM(l.outstanding_balance) AS outstanding_exposure
FROM customers c
INNER JOIN loans l
ON c.customer_id = l.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(l.loan_id) > 1
ORDER BY outstanding_exposure DESC;
-- Does credit score correlate with default risk?SELECT
SELECT
    CORR(
        c.credit_score,
        CASE
            WHEN l.loan_status='Defaulted' THEN 1
            ELSE 0
        END
    ) AS credit_score_default_correlation
FROM customers c
INNER JOIN loans l
ON c.customer_id = l.customer_id;
-- Which payments don't match scheduled amounts?
SELECT
    payment_id,
    loan_id,
    scheduled_amount,
    actual_payment,
    scheduled_amount - actual_payment AS discrepancy
FROM payments
WHERE scheduled_amount <> actual_payment
ORDER BY ABS(scheduled_amount - actual_payment) DESC;
-- Which loans have outstanding balances but no collateral?
SELECT
    l.loan_id,
    l.customer_id,
    l.loan_type,
    l.outstanding_balance
FROM loans l
LEFT JOIN collateral c
ON l.loan_id = c.loan_id
WHERE c.loan_id IS NULL
ORDER BY l.outstanding_balance DESC;
-- Which loans have LTV above 80%?
SELECT
    l.loan_id,
    l.outstanding_balance,
    c.collateral_value,
    ROUND(
        l.outstanding_balance * 100.0 /
        NULLIF(c.collateral_value,0),2
    ) AS ltv
FROM loans l
INNER JOIN collateral c
ON l.loan_id = c.loan_id
WHERE l.outstanding_balance * 100.0 /
      NULLIF(c.collateral_value,0) > 80
ORDER BY ltv DESC;
--Which loans have HIGH EXPOSURE + HIGH LTV + PAYMENT DELAYS?
WITH payment_risk AS (
    SELECT
        loan_id,
        MAX(days_past_due) AS max_dpd
    FROM payments
    GROUP BY loan_id
),
risk_loans AS (
    SELECT
        l.loan_id,
        l.customer_id,
        l.loan_type,
        l.outstanding_balance,
        c.collateral_value,

        ROUND(
            l.outstanding_balance * 100.0 /
            NULLIF(c.collateral_value,0),
            2
        ) AS ltv_pct,
        p.max_dpd
FROM loans l
LEFT JOIN collateral c
ON l.loan_id = c.loan_id
INNER JOIN payment_risk p
ON l.loan_id = p.loan_id
WHERE l.outstanding_balance > 500000
AND l.outstanding_balance * 100.0 /
NULLIF(c.collateral_value,0) > 80
AND p.max_dpd > 30
)
SELECT
    *,
    RANK() OVER (
        ORDER BY outstanding_balance DESC
    ) AS exposure_rank
FROM risk_loans
ORDER BY exposure_rank;