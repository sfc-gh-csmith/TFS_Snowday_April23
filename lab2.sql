-- =============================================================================
-- LAB 2: Build a Cortex Agent + Snowflake Intelligence
-- TFS Snowday  |  April 23, 2026  |  11:00 AM – 11:45 AM  (45 min)
-- =============================================================================
--
-- WHAT YOU WILL BUILD:
--   A Cortex Agent is an orchestrator that combines multiple tools — structured
--   data (via Cortex Analyst) and unstructured documents (via Cortex Search) —
--   into a single conversational interface.
--
--   You will create TFS_LAB_AGENT_<YOUR_USERNAME>, which wires together:
--     Tool 1 — PortfolioAnalyst: natural language → SQL on the TFS loan portfolio
--     Tool 2 — PolicySearch:     semantic search over TFS policy documents
--
--   Then you will chat with your agent through Snowflake Intelligence (the
--   AI & ML → Agents interface in Snowsight) to get answers that span
--   structured data AND policy context in a single conversation.
--
-- NOTE: This lab uses pre-staged objects built by your admin team:
--   LOAN_PORTFOLIO_SV   — semantic view on the TFS loan portfolio
--   POLICY_DOCS_CS      — Cortex Search service over TFS policy documents
--   You do NOT need to have completed Lab 1 to do this lab.
--
-- IMPORTANT — NAME YOUR OBJECT WITH YOUR USERNAME:
--   Replace <YOUR_USERNAME> in every statement below with your Snowflake
--   username (e.g. TFS_LAB_AGENT_JSMITH).
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
-- STEP 2: Confirm the pre-staged tools are ready
-- =============================================================================

-- 2a. The semantic view your agent will use for loan data analysis
SHOW SEMANTIC VIEWS LIKE 'LOAN_PORTFOLIO_SV' IN SCHEMA SNOWDAY_LAB_DB.LAB;

-- 2b. The Cortex Search service your agent will use for policy document search
SHOW CORTEX SEARCH SERVICES LIKE 'POLICY_DOCS_CS' IN SCHEMA SNOWDAY_LAB_DB.LAB;

-- 2c. Preview the policy documents indexed in the search service
SELECT DOC_ID, DOC_TITLE, DOC_TYPE FROM POLICY_DOCUMENTS;


-- =============================================================================
-- STEP 3: Understand the Agent structure
-- =============================================================================
--
-- A Cortex Agent is defined as a YAML specification inside a CREATE AGENT
-- statement. The spec has four main sections:
--
--   models       — which LLM orchestrates the conversation (default: auto)
--   instructions — how the agent should behave and route questions to tools
--   tools        — the list of tools the agent can call
--   tool_resources — the actual Snowflake objects backing each tool
--
-- Tool types used in this lab:
--   cortex_analyst_text_to_sql — takes a natural language question, generates
--                                SQL from a semantic view, executes it, and
--                                returns structured results
--   cortex_search              — takes a question, searches indexed documents,
--                                and returns the most relevant passages


-- =============================================================================
-- STEP 4: Create your Agent
-- Replace <YOUR_USERNAME> with your Snowflake username.
-- =============================================================================

CREATE OR REPLACE AGENT TFS_LAB_AGENT_<YOUR_USERNAME>
    COMMENT = 'My TFS Lab Agent - combines loan analytics and policy search'
    PROFILE = '{"display_name": "TFS Portfolio Assistant", "color": "blue"}'
    FROM SPECIFICATION
    $$
    models:
      orchestration: claude-4-sonnet

    orchestration:
      budget:
        seconds: 60
        tokens: 50000

    instructions:
      response: "Provide clear, concise answers relevant to auto finance. Format dollar amounts with $ and commas. Format percentages with one decimal place. Keep responses concise and actionable."
      orchestration: "For questions about loan volumes, balances, rates, credit scores, LTV, dealer performance, delinquency metrics, or any quantitative portfolio data use the PortfolioAnalyst tool. For questions about policies, underwriting criteria, dealer tier requirements, product terms, income verification, vehicle collateral, or any procedural question use the PolicySearch tool. When the question requires both data and policy context, use both tools and synthesize the results."
      system: "You are a financial analytics assistant for Toyota Financial Services. You help the TFS team analyze the auto loan portfolio and understand lending policies. You have access to TFS loan data and TFS policy documents."
      sample_questions:
        - question: "What is our total outstanding portfolio balance by dealer tier?"
          answer: "I will query the loan portfolio to break down outstanding balances by dealer tier."
        - question: "What are the underwriting requirements for a borrower with a 650 FICO score?"
          answer: "I will search the underwriting guidelines for near-prime credit requirements."
        - question: "Which region has the highest delinquency rate, and what action does policy require for those accounts?"
          answer: "I will check portfolio data for regional delinquency rates and then look up the policy for handling delinquent accounts."

    tools:
      - tool_spec:
          type: "cortex_analyst_text_to_sql"
          name: "PortfolioAnalyst"
          description: "Queries the TFS auto loan portfolio. Use for questions about loan counts, origination volumes, outstanding balances, interest rates, credit scores, LTV ratios, delinquency, dealer performance, or any quantitative portfolio question."
      - tool_spec:
          type: "cortex_search"
          name: "PolicySearch"
          description: "Searches TFS policy and product documentation. Use for questions about underwriting guidelines, dealer tier criteria, income verification, loan product terms, vehicle collateral standards, or any policy or procedural question."

    tool_resources:
      PortfolioAnalyst:
        semantic_view: "SNOWDAY_LAB_DB.LAB.LOAN_PORTFOLIO_SV"
      PolicySearch:
        name: "SNOWDAY_LAB_DB.LAB.POLICY_DOCS_CS"
        max_results: "5"
        title_column: "DOC_TITLE"
        id_column: "DOC_ID"
    $$;


-- =============================================================================
-- STEP 5: Verify your Agent was created
-- =============================================================================

SHOW AGENTS IN SCHEMA SNOWDAY_LAB_DB.LAB;

-- Find yours specifically:
DESCRIBE AGENT TFS_LAB_AGENT_<YOUR_USERNAME>;


-- =============================================================================
-- STEP 6: Chat with your Agent via Snowflake Intelligence
-- =============================================================================
--
-- Snowflake Intelligence is the conversational UI built into Snowsight.
-- It is powered by Cortex Agents. Here is how to access it:
--
--   1. In the Snowsight left sidebar, click "AI & ML"
--   2. Click "Agents"
--   3. Find "TFS_LAB_AGENT_<YOUR_USERNAME>" in the list and click it
--   4. Start asking questions in the chat box
--
-- Try these prompts — notice how each one may use one or both tools:
--
-- ── Structured data only (PortfolioAnalyst) ──────────────────────────────────
--   "How many loans do we have by dealer tier?"
--   "What is the average LTV for Gold tier dealers vs Bronze tier dealers?"
--   "Show me total origination volume by region for the last 2 years"
--   "Which 5 dealers have the highest outstanding balance?"
--   "What percentage of our portfolio is delinquent?"
--
-- ── Policy documents only (PolicySearch) ────────────────────────────────────
--   "What credit score is required for a Lexus lease?"
--   "What happens to a dealer when their delinquency rate exceeds 5%?"
--   "What vehicle titles are not accepted as collateral?"
--   "What are the income verification requirements for a self-employed borrower?"
--
-- ── Cross-tool questions (the real aha moment) ───────────────────────────────
--   "Which region has the highest average LTV and what does our policy say
--    about LTV limits for that loan type?"
--
--   "Show me the delinquency rate for Bronze tier dealers and what our
--    policy says about Bronze tier escalation procedures"
--
--   "What is our total exposure in Charged_Off loans and what action does
--    our underwriting policy require once a loan reaches charge-off?"
--
--   "I have a Tier 3 borrower (FICO 672) asking for a $45,000 Toyota Camry
--    retail loan. Is this approvable and what rate tier would they get?"


-- =============================================================================
-- STEP 7: Explore and extend  (if time permits)
-- =============================================================================
--
-- A. Modify the orchestration instructions to change how the agent routes
--    questions. For example, try making it always use both tools by default
--    and see how the response quality changes.
--
-- B. Add a second Analyst tool pointing at DEALER_PERFORMANCE_SV instead of
--    LOAN_PORTFOLIO_SV and ask dealer-specific questions.
--    Hint: copy the PortfolioAnalyst tool block, rename it to "DealerAnalyst",
--    and change the semantic_view to SNOWDAY_LAB_DB.LAB.DEALER_PERFORMANCE_SV.
--
-- C. Change the agent color in the PROFILE to "green" or "red" and see the
--    visual difference in the Snowflake Intelligence UI.
--
-- D. Try asking the same question multiple times with different phrasing.
--    Observe how synonyms defined in the semantic view help maintain accuracy.
--
-- Lab 2 complete. In Lab 3 you will explore Cortex Code, the AI coding
-- assistant built into every Snowsight SQL editor.
