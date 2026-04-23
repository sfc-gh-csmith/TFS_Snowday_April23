# TFS Snowday - Hands-On AI Lab

**Date:** April 23, 2026  

## What is this?

This is a hands-on lab where TFS team members will build and interact with three Snowflake AI capabilities using synthetic TFS auto loan data. No prior Snowflake AI experience is required. Each lab builds on the previous one, but attendees can join at any point since shared objects are pre-staged by the admin team.

## The Data

All labs use a synthetic TFS auto lending dataset loaded into `SNOWDAY_LAB_DB.LAB`:

| Table | Rows | Description |
|-------|------|-------------|
| `DEALERS` | 50 | Dealership records with tier (Gold/Silver/Bronze), region, and brand affiliation |
| `LOANS` | 500 | Loan records with amount, rate, LTV, credit score, status, and vehicle details |
| `PAYMENTS` | ~12,000 | Payment history with scheduled vs. paid amounts, days past due, running balance |
| `DELINQUENCY_EVENTS` | ~190 | 30/60/90 DPD events, charge-offs, and actions taken |
| `POLICY_DOCUMENTS` | 4 | Parsed text from TFS policy PDFs, XML product catalog, and dealer tier guidelines |

## Labs

### Lab 1: Build a Semantic View (45 min)
**File:** `lab1.sql`

Attendees create a **Semantic View** -- a native Snowflake object that defines the business meaning of data (dimensions, metrics, relationships, and synonyms) so that Cortex Analyst can answer natural language questions with accurate SQL.

**What you'll do:**
- Explore the LOANS and DEALERS tables to understand the data
- Create a Semantic View with dimensions (loan type, dealer tier, region, vehicle make, etc.) and metrics (loan count, total balance, average LTV, average credit score, etc.)
- Query the Semantic View using the `SEMANTIC_VIEW()` SQL function
- Open **Cortex Analyst** in Snowsight and ask questions in plain English like *"What is the total outstanding balance in the West region?"*

### Lab 2: Build a Cortex Agent + Snowflake Intelligence (45 min)
**File:** `lab2.sql`

Attendees create a **Cortex Agent** that combines two tools -- structured data analytics and unstructured document search -- into a single conversational interface.

**What you'll do:**
- Verify pre-staged objects: a semantic view (LOAN_PORTFOLIO_SV) and a Cortex Search service (POLICY_DOCS_CS) indexing TFS policy documents
- Create an Agent with a YAML specification that wires together:
  - **PortfolioAnalyst** -- natural language to SQL on the loan portfolio (via Cortex Analyst)
  - **PolicySearch** -- semantic search over underwriting guidelines, collateral policies, product catalogs, and dealer tier rules (via Cortex Search)
- Chat with the agent through **Snowflake Intelligence** (AI & ML > Agents in Snowsight)
- Ask cross-tool questions like *"Which region has the highest average LTV and what does our policy say about LTV limits?"*

### Lab 3: Cortex Code Exploration (30 min)
**File:** `lab3.sql`

Attendees use **Cortex Code** (CoCo), the AI coding assistant built into every Snowsight SQL editor, through four hands-on challenges.

**What you'll do:**
- **Challenge 1 - Explain:** Highlight a complex query with CTEs and window functions, then ask CoCo to explain it in plain English
- **Challenge 2 - Write:** Describe a report in natural language and have CoCo generate the SQL from scratch
- **Challenge 3 - Fix:** Give CoCo a broken query (GROUP BY mismatch) and ask it to find and fix the bug
- **Challenge 4 - Extend:** Open-ended exploration -- pick a table and use CoCo as a pair programmer to build something new

## Prerequisites

Before the lab begins, an admin must run the setup scripts (not included in this repo):

1. **enable.sql** (ACCOUNTADMIN) -- Creates the warehouse, database, schema, and role; enables Cortex AI features; grants the `SNOWDAY_LAB_ROLE` to attendees
2. **admin_prework.sql** (SNOWDAY_LAB_ROLE) -- Loads CSV data and policy documents into stages/tables, creates pre-staged semantic views, builds the Cortex Search index, and creates a reference agent

Attendees need:
- A Snowflake login with `SNOWDAY_LAB_ROLE` assigned
- Default role set to `SNOWDAY_LAB_ROLE` and default warehouse set to `SNOWDAY_LAB_WH`
- Access to Snowsight (the Snowflake web UI)

## Snowflake Features Covered

| Feature | Lab | What it does |
|---------|-----|-------------|
| **Semantic Views** | 1, 2 | Define business meaning on tables so AI can generate accurate SQL |
| **Cortex Analyst** | 1, 2 | Natural language to SQL -- ask questions, get answers |
| **Cortex Search** | 2 | Semantic search over unstructured documents (PDFs, XML, text) |
| **Cortex Agents** | 2 | Orchestrator that combines multiple AI tools in one conversation |
| **Snowflake Intelligence** | 2 | Conversational UI for interacting with agents in Snowsight |
| **Cortex Code (CoCo)** | 3 | AI coding assistant in the SQL editor -- explain, write, fix, extend |
