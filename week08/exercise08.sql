USE ROLE DOG_DATA5035_ROLE; 

-- DELIVERABLE ONE - BUS MATRIX
/**
     Rows    = Business processes that generate cost data
     Columns = Dimensions analysts use to slice and filter
     X       = Dimension applies to that business process
     
     =============================================================================
     Business Processes:
     1. Direct Materials Consumption  -- raw ingredient costs per batch
     2. Direct Labor                  -- operator hours and wages per batch
     3. Manufacturing Overhead        -- equipment, utilities, cleanroom allocation per batch
     4. Quality Control Testing       -- routine tests, sterility tests, failure investigations
    
     
     | Metric                  | Description                                              | Date (Batch Production) | Dim: Batch | Dim: Facility | Dim: Product | Dim: Cost Category |
     |-------------------------|----------------------------------------------------------|------------------------|------------|---------------|--------------|--------------------|
     | Actual Cost             | Total cost actually incurred for the process/batch       | X                      | X          | X             | X            | X                  |
     | Standard Cost           | Expected/budgeted cost for the process/batch             | X                      | X          | X             | X            | X                  |
     | Cost Variance           | Actual cost minus standard cost (+ = over budget)        | X                      | X          | X             | X            | X                  |
     | Variance % from Std     | (Actual - Standard) / Standard * 100                     | X                      | X          | X             | X            | X                  |
     | Cost Per Unit Produced  | Actual cost divided by units produced in the batch       | X                      | X          | X             | X            |                    |
     | Units Produced          | Number of units manufactured in the batch                | X                      | X          | X             | X            |                    |
     | Labor Hours             | Operator hours logged against the batch (incl. overtime) | X                      | X          | X             |              |                    |
    
     Business Processes:
     1. Direct Materials Consumption  -- raw ingredient costs per batch
     2. Direct Labor                  -- operator hours and wages per batch
     3. Manufacturing Overhead        -- equipment, utilities, cleanroom allocation per batch
     4. Quality Control Testing       -- routine tests, sterility tests, failure investigations
    
     =============================================================================
 */



-- DELIVERABLE TWO - STAR SCHEMA

/**
=============================================================================
--
-- GRAIN STATEMENT:
--   One row per batch per cost category per production date.
--   Example: Batch B-10454 × Direct Labor × 2024-04-15
--   This grain allows the CFO to:
--     - Roll up to total batch cost across all categories
--     - Slice by a single cost category across all batches/facilities
--     - Trend costs over time at any level of granularity
--
-- TABLE SUMMARY:
--   FACT_BATCH_COST       -- central fact table (one row per batch x cost category x date)
--   DIM_DATE              -- calendar dimension with surrogate key
--   DIM_BATCH             -- production batch attributes and QA status
--   DIM_FACILITY          -- manufacturing site attributes and cost rates
--   DIM_PRODUCT           -- drug product attributes and dosage form
--   DIM_COST_CATEGORY     -- cost category classification and type
-- =============================================================================
*/
 
-- -----------------------------------------------------------------------------
-- DIM_DATE
-- Standard calendar dimension. Surrogate key is an integer in YYYYMMDD format
-- for easy readability and range filtering without joins.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE DATA5035.DOG.DIM_DATE (
    date_key            INTEGER         NOT NULL,   -- surrogate key: YYYYMMDD (e.g., 20240415)
    full_date           DATE            NOT NULL,   -- actual calendar date
    day_of_week         VARCHAR(10)     NOT NULL,   -- e.g., 'Monday'
    day_of_week_num     SMALLINT        NOT NULL,   -- 1=Sunday ... 7=Saturday
    day_of_month        SMALLINT        NOT NULL,   -- 1-31
    week_of_year        SMALLINT        NOT NULL,   -- ISO week number 1-53
    month_num           SMALLINT        NOT NULL,   -- 1-12
    month_name          VARCHAR(10)     NOT NULL,   -- e.g., 'April'
    quarter_num         SMALLINT        NOT NULL,   -- 1-4
    quarter_label       VARCHAR(6)      NOT NULL,   -- e.g., 'Q2-2024'
    fiscal_year         SMALLINT        NOT NULL,   -- fiscal year (adjust offset as needed)
    calendar_year       SMALLINT        NOT NULL,   -- calendar year
    is_weekend          BOOLEAN         NOT NULL,   -- TRUE if Saturday or Sunday
    is_holiday          BOOLEAN         NOT NULL,   -- TRUE if company-observed holiday
    CONSTRAINT pk_dim_date PRIMARY KEY (date_key)
);
 
 
-- -----------------------------------------------------------------------------
-- DIM_FACILITY
-- One row per manufacturing site. Captures cost-driving attributes like
-- overhead rate and sterile classification that vary by location.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE DATA5035.DOG.DIM_FACILITY (
    facility_key        INTEGER         NOT NULL AUTOINCREMENT,  -- surrogate key
    facility_id         VARCHAR(10)     NOT NULL,   -- natural key: e.g., 'STL-A', 'COL-BC', 'RAL-S'
    facility_name       VARCHAR(100)    NOT NULL,   -- e.g., 'St. Louis Plant A'
    city                VARCHAR(50)     NOT NULL,   -- e.g., 'St. Louis'
    state               VARCHAR(2)      NOT NULL,   -- e.g., 'MO'
    is_sterile_facility BOOLEAN         NOT NULL,   -- TRUE for Columbus BioCenter (ISO 5 cleanroom)
    overhead_rate_per_hr DECIMAL(8,2)   NOT NULL,   -- allocated overhead $/hr (STL=180, COL=320, RAL=210)
    labor_sterile_premium_pct DECIMAL(5,4) NOT NULL, -- additional % for sterile ops (Columbus = 0.10)
    production_line_type VARCHAR(50)    NOT NULL,   -- e.g., 'Tablet Compression', 'Aseptic Fill-Finish', 'Ointment Mixing'
    operator_count_day  SMALLINT        NOT NULL,   -- standard operators on day shift
    operator_count_night SMALLINT       NOT NULL,   -- standard operators on night shift
    effective_start_date DATE           NOT NULL,   -- SCD Type 2: row valid from
    effective_end_date   DATE,                      -- SCD Type 2: NULL = currently active
    is_current          BOOLEAN         NOT NULL,   -- TRUE if this is the active row
    CONSTRAINT pk_dim_facility PRIMARY KEY (facility_key)
);
 
 
-- -----------------------------------------------------------------------------
-- DIM_PRODUCT
-- One row per drug product. Captures dosage form and product line, which
-- drive material composition and manufacturing complexity.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE DATA5035.DOG.DIM_PRODUCT (
    product_key         INTEGER         NOT NULL AUTOINCREMENT,  -- surrogate key
    product_id          VARCHAR(20)     NOT NULL,   -- natural key: internal product code
    product_name        VARCHAR(100)    NOT NULL,   -- e.g., 'Cardiolex', 'OptiClear', 'DermaSmooth'
    product_line        VARCHAR(50)     NOT NULL,   -- e.g., 'Cardiovascular', 'Ophthalmology', 'Dermatology'
    dosage_form         VARCHAR(50)     NOT NULL,   -- e.g., 'Tablet', 'Sterile Drops', 'Ointment'
    requires_sterile_mfg BOOLEAN        NOT NULL,   -- TRUE for OptiClear (aseptic fill-finish)
    standard_batch_duration_hrs DECIMAL(6,2) NOT NULL, -- expected production hours per batch (e.g., 12.0 for sterile)
    num_active_materials SMALLINT       NOT NULL,   -- count of direct materials (Cardiolex=3, OptiClear=2, DermaSmooth=3)
    regulatory_category VARCHAR(50)     NOT NULL,   -- e.g., 'Rx', 'OTC'
    CONSTRAINT pk_dim_product PRIMARY KEY (product_key)
);
 
 
-- -----------------------------------------------------------------------------
-- DIM_BATCH
-- One row per production batch. Captures batch-level attributes including
-- QA status, completion time, and rework flags that drive cost variances.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE DATA5035.DOG.DIM_BATCH (
    batch_key           INTEGER         NOT NULL AUTOINCREMENT,  -- surrogate key
    batch_id            VARCHAR(20)     NOT NULL,   -- natural key: e.g., 'B-10454'
    batch_number        VARCHAR(20)     NOT NULL,   -- display-friendly batch number
    batch_status        VARCHAR(20)     NOT NULL,   -- e.g., 'Released', 'Under QA Hold', 'Rejected'
    units_produced      INTEGER         NOT NULL,   -- total units manufactured in this batch
    actual_duration_hrs DECIMAL(6,2)    NOT NULL,   -- actual hours the line was occupied
    standard_duration_hrs DECIMAL(6,2)  NOT NULL,   -- expected hours for this product/facility
    qc_failures_count   SMALLINT        NOT NULL DEFAULT 0,  -- number of QC test failures (B-10454 = 2)
    rework_hours        DECIMAL(6,2)    NOT NULL DEFAULT 0,  -- overtime hours added for rework
    qa_hold_days        SMALLINT        NOT NULL DEFAULT 0,  -- days batch was held for QA investigation
    requires_rework     BOOLEAN         NOT NULL,   -- TRUE if batch required any rework
    batch_start_date    DATE            NOT NULL,   -- date manufacturing began
    batch_end_date      DATE,                       -- date batch was completed (NULL if in-progress)
    release_date        DATE,                       -- date QA released the batch (NULL if still held)
    CONSTRAINT pk_dim_batch PRIMARY KEY (batch_key)
);
 
 
-- -----------------------------------------------------------------------------
-- DIM_COST_CATEGORY
-- One row per cost category. Classifies costs into the four types defined
-- by the finance team: materials, labor, overhead, and QC testing.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE DATA5035.DOG.DIM_COST_CATEGORY (
    cost_category_key   INTEGER         NOT NULL AUTOINCREMENT,  -- surrogate key
    cost_category_id    VARCHAR(20)     NOT NULL,   -- natural key: e.g., 'DIR_MAT', 'DIR_LAB', 'MFG_OH', 'QC_TEST'
    cost_category_name  VARCHAR(50)     NOT NULL,   -- e.g., 'Direct Materials', 'Direct Labor'
    cost_type           VARCHAR(20)     NOT NULL,   -- 'Direct' or 'Indirect'
    cost_behavior       VARCHAR(20)     NOT NULL,   -- 'Variable', 'Fixed', or 'Semi-Variable'
    is_standard_costed  BOOLEAN         NOT NULL,   -- TRUE if a standard cost budget exists for this category
    description         VARCHAR(255)    NOT NULL,   -- plain-language description for BI tools
    CONSTRAINT pk_dim_cost_category PRIMARY KEY (cost_category_key)
);
 
 
-- -----------------------------------------------------------------------------
-- FACT_BATCH_COST
-- Central fact table at the grain of: one row per batch x cost category x date.
-- All monetary amounts are in USD. Variance = actual - standard (positive = over budget).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE DATA5035.DOG.FACT_BATCH_COST (
    -- Surrogate key
    batch_cost_key          INTEGER         NOT NULL AUTOINCREMENT,
 
    -- Foreign keys to all dimension tables
    date_key                INTEGER         NOT NULL,   -- FK -> DIM_DATE.date_key (production date)
    batch_key               INTEGER         NOT NULL,   -- FK -> DIM_BATCH.batch_key
    facility_key            INTEGER         NOT NULL,   -- FK -> DIM_FACILITY.facility_key
    product_key             INTEGER         NOT NULL,   -- FK -> DIM_PRODUCT.product_key
    cost_category_key       INTEGER         NOT NULL,   -- FK -> DIM_COST_CATEGORY.cost_category_key
 
    -- Quantitative measures: costs (USD)
    actual_cost             DECIMAL(12,2)   NOT NULL,   -- total actual cost for this category/batch
    standard_cost           DECIMAL(12,2)   NOT NULL,   -- expected/budgeted cost for this category/batch
    cost_variance           DECIMAL(12,2)   NOT NULL,   -- actual_cost - standard_cost (+ = over budget)
    cost_variance_pct       DECIMAL(8,4)    NOT NULL,   -- cost_variance / standard_cost * 100
 
    -- Quantitative measures: production volume and time
    units_produced          INTEGER         NOT NULL,   -- units manufactured (for cost-per-unit calculation)
    labor_hours_actual      DECIMAL(8,2),               -- actual operator hours (populated for labor category rows)
    labor_hours_standard    DECIMAL(8,2),               -- standard operator hours (populated for labor category rows)
    line_hours_actual       DECIMAL(8,2),               -- actual production line hours occupied (for overhead rows)
    line_hours_standard     DECIMAL(8,2),               -- standard line hours (for overhead rows)
 
    -- Audit columns
    load_timestamp          TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    source_system           VARCHAR(50)     NOT NULL,   -- originating system, e.g., 'ERP', 'MES', 'LIMS'
 
    -- Constraints
    CONSTRAINT pk_fact_batch_cost   PRIMARY KEY (batch_cost_key),
    CONSTRAINT fk_fbc_date          FOREIGN KEY (date_key)          REFERENCES DATA5035.DOG.DIM_DATE (date_key),
    CONSTRAINT fk_fbc_batch         FOREIGN KEY (batch_key)         REFERENCES DATA5035.DOG.DIM_BATCH (batch_key),
    CONSTRAINT fk_fbc_facility      FOREIGN KEY (facility_key)      REFERENCES DATA5035.DOG.DIM_FACILITY (facility_key),
    CONSTRAINT fk_fbc_product       FOREIGN KEY (product_key)       REFERENCES DATA5035.DOG.DIM_PRODUCT (product_key),
    CONSTRAINT fk_fbc_cost_category FOREIGN KEY (cost_category_key) REFERENCES DATA5035.DOG.DIM_COST_CATEGORY (cost_category_key)
);

--===================================================================================================

-- DELIVERABLE THREE - FLATTENED ML TABLE

CREATE OR REPLACE TABLE DATA5035.DOG.ML_BATCH_COST_FEATURES (
 
    -- -------------------------------------------------------------------------
    -- Batch identity (traceability -- exclude from model feature set)
    -- -------------------------------------------------------------------------
    batch_id                    VARCHAR(20)     NOT NULL,   -- e.g., 'B-10454'
    batch_start_date            DATE            NOT NULL,   -- manufacturing start date
    batch_end_date              DATE,                       -- manufacturing end date (NULL if in-progress)
    production_month            VARCHAR(7)      NOT NULL,   -- e.g., '2024-04' for time-based train/test splits
 
    -- -------------------------------------------------------------------------
    -- Facility features (denormalized from DIM_FACILITY)
    -- -------------------------------------------------------------------------
    facility_id                 VARCHAR(10)     NOT NULL,   -- e.g., 'STL-A', 'COL-BC', 'RAL-S'
    facility_name               VARCHAR(100)    NOT NULL,   -- e.g., 'St. Louis Plant A'
    is_sterile_facility         BOOLEAN         NOT NULL,   -- TRUE = Columbus BioCenter (ISO 5 cleanroom)
    facility_overhead_rate_hr   DECIMAL(8,2)    NOT NULL,   -- $/hr overhead allocation (STL=180, COL=320, RAL=210)
    labor_sterile_premium_pct   DECIMAL(5,4)    NOT NULL,   -- sterile labor premium (Columbus = 0.10, others = 0.00)
    production_line_type        VARCHAR(50)     NOT NULL,   -- e.g., 'Aseptic Fill-Finish', 'Tablet Compression'
 
    -- -------------------------------------------------------------------------
    -- Product features (denormalized from DIM_PRODUCT)
    -- -------------------------------------------------------------------------
    product_id                  VARCHAR(20)     NOT NULL,   -- internal product code
    product_name                VARCHAR(100)    NOT NULL,   -- e.g., 'Cardiolex', 'OptiClear', 'DermaSmooth'
    dosage_form                 VARCHAR(50)     NOT NULL,   -- e.g., 'Tablet', 'Sterile Drops', 'Ointment'
    requires_sterile_mfg        BOOLEAN         NOT NULL,   -- TRUE for OptiClear aseptic fill-finish
    num_active_materials        SMALLINT        NOT NULL,   -- number of direct material inputs (complexity proxy)
    standard_batch_duration_hrs DECIMAL(6,2)    NOT NULL,   -- expected line hours for this product
 
    -- -------------------------------------------------------------------------
    -- Labor features (denormalized from DIM_BATCH + FACT_BATCH_COST labor rows)
    -- -------------------------------------------------------------------------
    labor_hours_actual          DECIMAL(8,2)    NOT NULL,   -- total operator hours logged
    labor_hours_standard        DECIMAL(8,2)    NOT NULL,   -- expected operator hours for this batch
    labor_hours_variance        DECIMAL(8,2)    NOT NULL,   -- actual - standard (+ = more hours than planned)
    rework_hours                DECIMAL(6,2)    NOT NULL,   -- overtime hours added due to rework (B-10454 = 14)
    day_shift_hrs               DECIMAL(8,2)    NOT NULL,   -- hours worked at day shift rate ($45/hr)
    night_shift_hrs             DECIMAL(8,2)    NOT NULL,   -- hours worked at night shift rate ($52/hr)
 
    -- -------------------------------------------------------------------------
    -- Overhead features (denormalized from DIM_BATCH + FACT_BATCH_COST overhead rows)
    -- -------------------------------------------------------------------------
    line_hours_actual           DECIMAL(8,2)    NOT NULL,   -- actual hours the production line was occupied
    line_hours_standard         DECIMAL(8,2)    NOT NULL,   -- standard line hours for this product/facility
    line_hours_variance         DECIMAL(8,2)    NOT NULL,   -- actual - standard line hours (B-10454 = +1.5 hrs)
    qa_hold_days                SMALLINT        NOT NULL,   -- days batch was held under QA (drives cold-storage cost)
 
    -- -------------------------------------------------------------------------
    -- QC features (denormalized from DIM_BATCH + FACT_BATCH_COST QC rows)
    -- -------------------------------------------------------------------------
    qc_failures_count           SMALLINT        NOT NULL,   -- number of test failures (B-10454 = 2)
    qc_tests_total              SMALLINT        NOT NULL,   -- total number of QC tests performed
    qc_includes_sterility_test  BOOLEAN         NOT NULL,   -- TRUE if a $800 sterility test was required
    qc_failure_investigation_cost DECIMAL(10,2) NOT NULL,   -- cost of failure investigations ($1,200-$2,500 each)
 
    -- -------------------------------------------------------------------------
    -- Cost features by category (aggregated from FACT_BATCH_COST)
    -- -------------------------------------------------------------------------
    materials_actual_cost       DECIMAL(12,2)   NOT NULL,   -- total direct materials cost
    materials_standard_cost     DECIMAL(12,2)   NOT NULL,   -- standard direct materials cost
    materials_variance          DECIMAL(12,2)   NOT NULL,   -- materials actual - standard
 
    labor_actual_cost           DECIMAL(12,2)   NOT NULL,   -- total direct labor cost
    labor_standard_cost         DECIMAL(12,2)   NOT NULL,   -- standard direct labor cost
    labor_variance              DECIMAL(12,2)   NOT NULL,   -- labor actual - standard
 
    overhead_actual_cost        DECIMAL(12,2)   NOT NULL,   -- total overhead allocated
    overhead_standard_cost      DECIMAL(12,2)   NOT NULL,   -- standard overhead allocation
    overhead_variance           DECIMAL(12,2)   NOT NULL,   -- overhead actual - standard
 
    qc_actual_cost              DECIMAL(12,2)   NOT NULL,   -- total QC testing cost (routine + investigations)
    qc_standard_cost            DECIMAL(12,2)   NOT NULL,   -- standard QC cost (routine tests only)
    qc_variance                 DECIMAL(12,2)   NOT NULL,   -- qc actual - standard (investigations drive this up)
 
    total_actual_cost           DECIMAL(12,2)   NOT NULL,   -- sum of all four cost categories actual
    total_standard_cost         DECIMAL(12,2)   NOT NULL,   -- sum of all four cost categories standard
    total_cost_variance         DECIMAL(12,2)   NOT NULL,   -- total actual - total standard
    total_cost_variance_pct     DECIMAL(8,4)    NOT NULL,   -- total_cost_variance / total_standard_cost * 100
    cost_per_unit               DECIMAL(10,4)   NOT NULL,   -- total_actual_cost / units_produced
    units_produced              INTEGER         NOT NULL,   -- total units manufactured in the batch
 
    -- -------------------------------------------------------------------------
    -- Target variable (label for supervised binary classification)
    -- -------------------------------------------------------------------------
    exceeded_standard_cost_15pct BOOLEAN        NOT NULL,   -- TRUE if total_cost_variance_pct > 15.0
                                                            -- this is the value the model learns to predict
 
    -- -------------------------------------------------------------------------
    -- Audit columns
    -- -------------------------------------------------------------------------
    load_timestamp              TIMESTAMP_NTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP(),
 
    CONSTRAINT pk_ml_batch_cost_features PRIMARY KEY (batch_id)
);

/**
COMMENT 

'Flattened ML feature table -- one row per batch, everything denormalized so no joins needed.
 
What can you do with this table?
 
       1. Predict cost overruns early: Train a binary classifier to flag batches likely to
          bust their standard cost by 15%+ before they finish. The model can pick up on
          early warning signals like a high QC failure count, a sterile facility, or labor
          hours already running over standard -- and surface those batches to the ops team
          while there is still time to do something about it.

       2. Figure out what actually drives overruns: Run a feature importance analysis to
          see which variables matter most. Is it always the sterile batches at Columbus?
          Does a single QC failure reliably predict a second one? Does night shift labor
          correlate with higher total cost? This table makes those questions easy to explore.

       3. Cluster batches by cost profile: Use unsupervised clustering (k-means, etc.) to
          group batches that look similar -- e.g., a cluster of high-overhead sterile batches
          vs. a cluster of cheap straightforward tablet runs. Useful for the finance team
          when setting standard costs for next year.

       4. Forecast cost per unit: Swap the target variable for cost_per_unit and train a
          regression model. Helpful for pricing and margin analysis by product line.
*/