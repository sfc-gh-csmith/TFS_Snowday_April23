-- =============================================================================
-- LAB 3: Cortex Code (CoCo) Exploration
-- TFS Snowday  |  April 23, 2026  |  11:45 AM – 12:15 PM  (30 min)
-- =============================================================================
--
-- WHAT YOU WILL DO:
--   Cortex Code is Snowflake's AI coding assistant, built directly into the
--   Snowsight SQL editor. The sparkle icon (✦) in the top-right corner of
--   every worksheet opens a chat panel where you can ask for help with SQL —
--   explain code, write queries, fix bugs, and explore data.
--
--   This lab is structured as 4 short challenges. Each challenge is designed
--   to be completed in ~6 minutes. Use the sparkle icon for each one.
--
-- HOW TO USE CORTEX CODE:
--   1. Open a worksheet in Snowsight
--   2. Click the sparkle icon (✦) in the top-right corner of the editor
--   3. A chat panel opens on the right side
--   4. Type your question or request and press Enter
--   5. CoCo can see the SQL in your worksheet as context
--
-- PREREQUISITES:
--   Role:      SNOWDAY_LAB_ROLE
--   Warehouse: SNOWDAY_LAB_WH
--   Database:  SNOWDAY_LAB_DB
--   Schema:    SNOWDAY_LAB_DB.LAB
-- =============================================================================


USE ROLE      SNOWDAY_LAB_ROLE;
USE WAREHOUSE SNOWDAY_LAB_WH;
USE DATABASE  SNOWDAY_LAB_DB;
USE SCHEMA    SNOWDAY_LAB_DB.LAB;


-- =============================================================================
-- CHALLENGE 1: Explain  (~6 min)
-- =============================================================================
--
-- The query below is something a data engineer left behind. It does something
-- useful but no one documented it. Your task:
--
--   → Highlight the query below, then open the sparkle icon and type:
--     "Explain what this query does in plain English"
--
-- After reading CoCo's explanation, run the query and verify the results match.

WITH monthly_stats AS (
    SELECT
        DATE_TRUNC('month', l.ORIGINATION_DATE)   AS origination_month,
        d.DEALER_TIER,
        d.REGION,
        COUNT(l.LOAN_ID)                           AS loan_count,
        SUM(l.LOAN_AMOUNT)                         AS total_funded,
        SUM(l.OUTSTANDING_BALANCE)                 AS total_outstanding,
        AVG(l.CREDIT_SCORE)                        AS avg_credit_score,
        AVG(l.LTV_RATIO)                           AS avg_ltv
    FROM   LOANS   l
    JOIN   DEALERS d ON l.DEALER_ID = d.DEALER_ID
    GROUP  BY 1, 2, 3
),
ranked AS (
    SELECT
        origination_month,
        DEALER_TIER,
        REGION,
        loan_count,
        total_funded,
        total_outstanding,
        ROUND(avg_credit_score, 0)                 AS avg_fico,
        ROUND(avg_ltv * 100, 1)                    AS avg_ltv_pct,
        SUM(total_funded) OVER (
            PARTITION BY DEALER_TIER
            ORDER BY origination_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                          AS cumulative_funded_by_tier,
        ROUND(
            total_funded / NULLIF(
                SUM(total_funded) OVER (PARTITION BY origination_month), 0
            ) * 100, 1
        )                                          AS pct_of_monthly_volume
    FROM monthly_stats
)
SELECT *
FROM   ranked
WHERE  origination_month >= DATEADD('year', -2, DATE_TRUNC('month', CURRENT_DATE()))
ORDER  BY origination_month DESC, DEALER_TIER, total_funded DESC;


-- =============================================================================
-- CHALLENGE 2: Write  (~6 min)
-- =============================================================================
--
-- You need a new report but do not want to write the SQL from scratch.
-- Your task:
--
--   → Open the sparkle icon and type this prompt (or your own version):
--     "Write a SQL query that shows the delinquency rate by state for active
--      and delinquent loans. Include total loan count, delinquent count, and
--      delinquency rate as a percentage. Sort by delinquency rate descending."
--
-- CoCo will generate the SQL. Paste it below this comment block and run it.
-- Check: does the result make sense? Do the totals add up?
--
-- ── Paste CoCo's generated SQL here ──────────────────────────────────────────




-- =============================================================================
-- CHALLENGE 3: Fix  (~6 min)
-- =============================================================================
--
-- The query below was written in a hurry and has a bug. It should show
-- average LTV and average credit score for each dealer tier, but the results
-- look wrong. Your task:
--
--   → Highlight the broken query, open the sparkle icon, and type:
--     "This query has a bug. Find it and fix it."
--
-- After CoCo identifies the issue, apply the fix and confirm the query runs.

SELECT
    d.DEALER_TIER,
    d.REGION,
    COUNT(l.LOAN_ID)       AS loan_count,
    AVG(l.LTV_RATIO)       AS avg_ltv,
    AVG(l.CREDIT_SCORE)    AS avg_credit_score
FROM   LOANS l
JOIN   DEALERS d ON l.DEALER_ID = d.DEALER_ID
WHERE  l.LOAN_STATUS = 'Active'
   AND l.ORIGINATION_DATE >= '2024-01-01'
GROUP  BY d.DEALER_TIER
ORDER  BY loan_count DESC;
-- Hint: look carefully at what is in the SELECT vs what is in the GROUP BY.


-- =============================================================================
-- CHALLENGE 4: Extend  (~10 min)
-- =============================================================================
--
-- This one is open-ended. Pick any of the four tables in SNOWDAY_LAB_DB.LAB
-- and build something new using CoCo as your pair programmer.
--
-- The tables available:
--   LOANS              (loan records with status, amount, rate, LTV)
--   DEALERS            (dealer name, tier, region, state)
--   PAYMENTS           (payment history, days past due, running balance)
--   DELINQUENCY_EVENTS (30/60/90 DPD events, charge-offs, actions taken)
--
-- Some ideas to get you started — or use your own:
--
--   A. "Write a query that identifies which loans have made at least one
--      Partial or Missed payment in the last 6 months"
--
--   B. "Write a query showing the payment performance trend by quarter —
--      what percent of payments were on-time vs partial vs missed?"
--
--   C. "I want to see the full delinquency lifecycle: for each loan that
--      eventually charged off, show the sequence of events in order"
--
--   D. "Write a query that compares Gold vs Bronze dealers: side by side
--      average credit score, average LTV, delinquency rate, and total
--      outstanding balance"
--
--   E. Come up with your own question about TFS loan data and build it.
--
-- ── Your query here ───────────────────────────────────────────────────────────




-- =============================================================================
-- BONUS: Things to try if you want to go deeper
-- =============================================================================
--
-- 1. Ask CoCo to add comments to a query you wrote:
--    "Add inline comments explaining each step of this query"
--
-- 2. Ask CoCo to optimize a slow query:
--    "How could this query be made more efficient for a large table?"
--
-- 3. Ask CoCo to convert a subquery to a CTE (or vice versa):
--    "Rewrite this query using CTEs instead of subqueries"
--
-- 4. Ask CoCo to write a query using a window function you have not used before:
--    "Write a query that uses LAG() to show the month-over-month change
--     in total originations by dealer tier"
--
-- 5. Paste an error message from a failed query into CoCo and ask:
--    "I got this error — what does it mean and how do I fix it?"
--
-- =============================================================================
-- End of Lab 3 — and the end of the hands-on portion of TFS Snowday!
-- Thank you for participating. Questions? Connect with the TFS team or
-- reach out via the Snowflake account team.
-- =============================================================================
