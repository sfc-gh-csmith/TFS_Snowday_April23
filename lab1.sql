-- =============================================================================
-- LAB 1: Build a Semantic View
-- TFS Snowday  |  April 23, 2026  |  10:15 AM – 11:00 AM  (45 min)
-- =============================================================================
--
-- WHAT YOU WILL BUILD:
--   A Semantic View is a native Snowflake object that defines the business
--   meaning of your data — dimensions, metrics, and relationships — so that
--   Cortex Analyst can answer natural language questions with accurate SQL.
--
--   You will build LOAN_SV_<YOUR_USERNAME> on top of two pre-loaded TFS
--   tables (LOANS and DEALERS) and then query it in plain English.
--
-- IMPORTANT — NAME YOUR OBJECT WITH YOUR USERNAME:
--   Replace <YOUR_USERNAME> in every statement below with your Snowflake
--   username (e.g. LOAN_SV_JSMITH). This ensures everyone's semantic view
--   stays separate. Ask the facilitator if you are unsure of your username.
--
-- PREREQUISITES:
--   Role:      SNOWDAY_LAB_ROLE
--   Warehouse: SNOWDAY_LAB_WH
--   Database:  SNOWDAY_LAB_DB
--   Schema:    SNOWDAY_LAB_DB.LAB
-- =============================================================================


-- =============================================================================
-- STEP 1: Set your context
-- =============================================================================

USE ROLE      SNOWDAY_LAB_ROLE;
USE WAREHOUSE SNOWDAY_LAB_WH;
USE DATABASE  SNOWDAY_LAB_DB;
USE SCHEMA    SNOWDAY_LAB_DB.LAB;


-- =============================================================================
-- STEP 2: Explore the data
-- Run these queries to get familiar with what we are working with.
-- =============================================================================

-- 2a. What does a loan record look like?
SELECT * FROM LOANS LIMIT 10;

-- 2b. What columns are available?
DESCRIBE TABLE LOANS;
DESCRIBE TABLE DEALERS;

-- 2c. How many loans by status?
SELECT LOAN_STATUS, COUNT(*) AS loan_count
FROM   LOANS
GROUP  BY LOAN_STATUS
ORDER  BY loan_count DESC;

-- 2d. What dealer tiers exist?
SELECT DEALER_TIER, COUNT(*) AS dealer_count
FROM   DEALERS
GROUP  BY DEALER_TIER;

-- 2e. How do the two tables relate?
SELECT  l.LOAN_ID,
        l.LOAN_AMOUNT,
        l.LOAN_STATUS,
        d.DEALER_NAME,
        d.DEALER_TIER,
        d.REGION
FROM    LOANS    l
JOIN    DEALERS  d ON l.DEALER_ID = d.DEALER_ID
LIMIT   10;


-- =============================================================================
-- STEP 3: Understand the Semantic View structure
-- =============================================================================
--
-- A Semantic View has four key building blocks:
--
--   TABLES       — the source tables (with optional aliases and primary keys)
--   RELATIONSHIPS— how the tables join (foreign key → primary key)
--   DIMENSIONS   — categorical columns for grouping/filtering
--                  (loan type, region, dealer tier, etc.)
--   METRICS      — numeric aggregations
--                  (loan count, total balance, avg LTV, etc.)
--
-- Cortex Analyst reads this definition to understand your data model and
-- generate accurate SQL from plain English questions.


-- =============================================================================
-- STEP 4: Create your Semantic View
-- Replace <YOUR_USERNAME> with your Snowflake username (e.g. JSMITH).
-- =============================================================================

CREATE OR REPLACE SEMANTIC VIEW LOAN_SV_<YOUR_USERNAME>

    -- SOURCE TABLES ----------------------------------------------------------
    TABLES (
        l AS SNOWDAY_LAB_DB.LAB.LOANS
            PRIMARY KEY (LOAN_ID),
        d AS SNOWDAY_LAB_DB.LAB.DEALERS
            PRIMARY KEY (DEALER_ID)
    )

    -- HOW THEY JOIN ----------------------------------------------------------
    RELATIONSHIPS (
        loan_to_dealer AS l(DEALER_ID) REFERENCES d(DEALER_ID)
    )

    -- DIMENSIONS: categorical columns that users will filter and group by ----
    DIMENSIONS (
        l.LOAN_TYPE       AS loan_type
            WITH SYNONYMS = ('financing type', 'contract type', 'product type')
            COMMENT = 'Retail, Lease, or Balloon',

        l.PRODUCT_NAME    AS product_name
            WITH SYNONYMS = ('product', 'loan product', 'finance product')
            COMMENT = 'Full product name (e.g. Toyota Standard Retail)',

        l.LOAN_STATUS     AS loan_status
            WITH SYNONYMS = ('status', 'account status')
            COMMENT = 'Active, Delinquent, Charged_Off, or Paid_Off',

        l.STATE           AS state
            WITH SYNONYMS = ('borrower state', 'state', 'location', 'geography')
            COMMENT = 'State where the vehicle is registered',

        l.VEHICLE_MAKE    AS vehicle_make
            WITH SYNONYMS = ('make', 'brand', 'manufacturer')
            COMMENT = 'Toyota or Lexus',

        l.VEHICLE_MODEL   AS vehicle_model
            WITH SYNONYMS = ('model')
            COMMENT = 'Vehicle model (Camry, RAV4, ES 350, etc.)',

        l.TERM_MONTHS     AS term_months
            WITH SYNONYMS = ('term', 'loan term', 'contract length'),

        d.DEALER_TIER     AS dealer_tier
            WITH SYNONYMS = ('tier', 'dealer level', 'dealer grade')
            COMMENT = 'Gold, Silver, or Bronze',

        d.REGION          AS region
            WITH SYNONYMS = ('area', 'geographic region', 'territory')
            COMMENT = 'Northeast, Southeast, Midwest, West, or Southwest',

        d.DEALER_NAME     AS dealer_name
            WITH SYNONYMS = ('dealer', 'dealership')
    )

    -- METRICS: numeric aggregations that users will measure -------------------
    METRICS (
        l.loan_count AS COUNT(l.LOAN_ID)
            WITH SYNONYMS = ('number of loans', 'loan volume', 'count', 'originations')
            COMMENT = 'Total number of loans',

        l.total_origination_amount AS SUM(l.LOAN_AMOUNT)
            WITH SYNONYMS = ('origination volume', 'total funded', 'dollars originated')
            COMMENT = 'Total dollar amount of loans originated',

        l.total_outstanding_balance AS SUM(l.OUTSTANDING_BALANCE)
            WITH SYNONYMS = ('outstanding balance', 'portfolio balance', 'total balance')
            COMMENT = 'Total outstanding balance across the portfolio',

        l.avg_loan_amount AS AVG(l.LOAN_AMOUNT)
            WITH SYNONYMS = ('average loan', 'mean loan amount')
            COMMENT = 'Average loan origination amount',

        l.avg_interest_rate AS AVG(l.INTEREST_RATE)
            WITH SYNONYMS = ('average rate', 'average APR', 'mean rate')
            COMMENT = 'Average interest rate (stored as percent, e.g. 6.5 = 6.5%)',

        l.avg_credit_score AS AVG(l.CREDIT_SCORE)
            WITH SYNONYMS = ('average FICO', 'average credit score', 'credit quality')
            COMMENT = 'Average borrower FICO credit score',

        l.avg_ltv AS AVG(l.LTV_RATIO)
            WITH SYNONYMS = ('average LTV', 'loan to value')
            COMMENT = 'Average loan-to-value ratio (0.85 = 85%)'
    )

    COMMENT = 'TFS Loan Portfolio semantic view for Lab 1 — natural language querying on loan + dealer data'
    AI_SQL_GENERATION 'LTV_RATIO is stored as a decimal (0.85 = 85%). INTEREST_RATE is stored as a percent (6.5 = 6.5%). For delinquency rate calculations, filter LOAN_STATUS IN (''Delinquent'', ''Charged_Off''). Use ORIGINATION_DATE for time-based analysis.';


-- =============================================================================
-- STEP 5: Verify your Semantic View was created
-- =============================================================================

-- List all semantic views in the schema
SHOW SEMANTIC VIEWS IN SCHEMA SNOWDAY_LAB_DB.LAB;

-- Inspect the dimensions you defined
SHOW SEMANTIC DIMENSIONS IN SEMANTIC VIEW LOAN_SV_<YOUR_USERNAME>;

-- Inspect the metrics you defined
SHOW SEMANTIC METRICS IN SEMANTIC VIEW LOAN_SV_<YOUR_USERNAME>;


-- =============================================================================
-- STEP 6: Query your Semantic View with SQL  (optional warm-up)
-- The SEMANTIC_VIEW() function lets you query the view programmatically.
-- Cortex Analyst (next step) does this automatically from natural language.
-- =============================================================================

-- How many loans by dealer tier?
SELECT *
FROM SEMANTIC_VIEW(
    LOAN_SV_<YOUR_USERNAME>
    DIMENSIONS d.dealer_tier
    METRICS    l.loan_count, l.total_origination_amount, l.avg_credit_score
);

-- Outstanding balance by region and loan status?
SELECT *
FROM SEMANTIC_VIEW(
    LOAN_SV_<YOUR_USERNAME>
    DIMENSIONS d.region, l.loan_status
    METRICS    l.total_outstanding_balance, l.loan_count
);


-- =============================================================================
-- STEP 7: Query with Cortex Analyst (natural language)
-- =============================================================================
--
-- Now the fun part. Open Cortex Analyst in Snowsight:
--
--   Snowsight → AI & ML → Cortex Analyst
--   → Click "Select a semantic model or view"
--   → Choose SNOWDAY_LAB_DB > LAB > LOAN_SV_<YOUR_USERNAME>
--   → Ask questions in the chat box
--
-- Try these prompts:
--
--   "How many loans do we have by dealer tier?"
--   "What is the total outstanding balance in the West region?"
--   "Show me average LTV and average credit score by loan type"
--   "Which states have the highest origination volume?"
--   "What is the breakdown of loan status for Gold tier dealers?"
--   "Show me the top 5 vehicle models by total loans originated"
--
-- Notice how Cortex Analyst generates SQL from your question, runs it, and
-- returns results — all driven by the semantic view you just built.


-- =============================================================================
-- STEP 8: Explore and extend  (if time permits)
-- =============================================================================
--
-- Ideas to try if you finish early:
--
-- A. Add a synonym to an existing dimension and see if it changes how
--    Cortex Analyst understands a rephrased question.
--    Example: add 'credit tier' as a synonym for LOAN_STATUS.
--
-- B. Add the ORIGINATION_DATE column as a new dimension so you can ask
--    time-based questions like "show me loan volume by quarter".
--    Hint: add this inside the DIMENSIONS block:
--
--      l.ORIGINATION_DATE AS origination_date
--          WITH SYNONYMS = ('origination date', 'funded date', 'contract date')
--          COMMENT = 'Date the loan was originated'
--
-- C. Try asking a question Cortex Analyst cannot answer yet (e.g. "show me
--    payment history") — observe how it responds when the data is not in scope.
--
-- Lab 1 complete. In Lab 2 you will use a semantic view like this one as a
-- tool inside a Cortex Agent alongside unstructured policy documents.
