# Inventory Optimization 
## I. OVERALL
## 1. Executive Summary
**Objective:** Engineered an automated **Inventory Requirement Model** to establish **Target Stock Levels (TSL)** for 500 unique store-item combinations to **resolves the "Overstock vs. Stock-out" paradox**. Based on the assumption of ordering once every 7 days, the model maintains a 99% Service Level while the excess rate is at 20%.
## 2. Key Project Insights
- **High-Precision Seasonality:** Identified significant variance between weekday demand and weekly averages that traditional model overlook. By incorporating these fluctuations, the model generates highly accurate, day-specifi demand forecasts.
- **Automated Promotion Detection:** Developed a statistical outlier detection model (Basline 30day + 2 standard deviation) to flag missing promotion dates and calculate a **Promotion Lift Factor**, reducing shortage risks during high-traffic events.
- **Strategic Capital Allocation:** Implemented ABC Revenue Classification to priortize Class A items driving 80% of total revenue, ensuring 90% daily availability for top-performers while minimizing the "carrying cost" of slow-moving (Class C) stock.
- **Validated Reliability:** Conducted a rigorous 12-month backtest to prove model stability and financial impact before proposing operational deployment.
-----------------------------
## II. ANALYTICAL FRAMEWORK: A 6-STAGE DEEP DIVE
## 1. Ask
The primary goal was to engineer a scalable replenishment engine to solve the "Overstock vs. Stock-out" paradox. The project targeted a 97%+ success level while minimizing capital lock-up in slow-moving stock.
## 2. Prepare
### Data Sourcing:
The raw dataset was originally sourced from Kaggle with **913,000 rows** (Store Item Demand Forecasting Challenge). For this analysis, the data has been ingested into a SQL Server environment. This setup allows for the high-performance processing required to handle the 5-year history of daily sales across 10 stores and 50 items.
### Data Storage
A tiered strategy in MS SQL Server was used to ensure integrity:
- Bronze Layer: Contains immutable raw CSV imports as a “Single Source of Truth”.
- Silver Layer: Contains processed datasets (remove duplicate, error data, add new column ….)
- Gold Layer: Contains cleaned, validated dataset and new calculating columns for staged analysis.
  
## 3. Process (Data Engineering & Cleaning)
<img width="810" height="431" alt="image" src="https://github.com/user-attachments/assets/ad1d22a8-d48d-4379-99fe-c259cbf1e582" />

### A. Bronze to Silver
#### Data integrity and consistency verification
Data integrity Verification: Used `COUNT(DISTINCT item)` grouped by store to ensure that no store lost product. \
Data consistency Verification:
- Verifying data duplication by checking the composite key of `date` + `store` + `item` has zero duplicates, ensuring that the dataset will be accurate and not double-counted.
- Checking data errors to ensure no null values and no zero sales. Removed one row have zero sales.
#### Data enrichment
New drived columns were created to unlock deeper insight:
- Temporal Feature: calculating new column such as week_calendar to enable calculate the weekly inventory, extracting weekday_name and weekday_number to enable calculate the seasonality of weekday sales, creating new column dwh_create_date to manage data daily updated.
- Primary Key: create primary_key to manage data.
### B. Silver to Gold
Using **Star Schema Model** to optimize the performance when updating new data.
#### a. gold.dim_seasonality_index table *([CLick to jump SQL Script](https://github.com/Phuctran-81/Reorder-Point-Setup-Model/blob/main/scripts/gold/proc_load_gold_dim_seasonality_index.sql))*
- Calculating the average of the ratio between weekday sales and average week sales to get seasonality index of each weekday.
- Performed ROW_NUMBER () to create primary key for this table.
#### b. gold.dim_category *([Click to jump to SQL Script](https://github.com/Phuctran-81/Reorder-Point-Setup-Model/blob/main/scripts/gold/proc_load_gold_dim_category.sql))*
- Performed Window function rolling-sum the percentage of revenue of each item at each store to cagorize the item.
- Performed ROW_NUMBER () to create primary key for this table.
#### c. Gold.fact_train *([Click to jump to SQL Script](https://github.com/Phuctran-81/Reorder-Point-Setup-Model/blob/main/scripts/gold/proc_load_gold_fact_train.sql))*
- Performed Window_function to calculate the 30 day average sales of each item at each store and the 30 day standard deviation of sales of each item at each store.
- Flagging the promotion day by detecting days where sales > 30 day average sales + 2 * 30 day standard deviation.
- Performed JOIN function to get foreign key from gold.dim_category and gold.dim_seasonality_index table.
- Finally, filter out 30 first days of each item at each store (15.000 rows), that rows miss data to calculate the complete 30 day average sales and 30 day standard deviation.
<img width="1115" height="704" alt="image" src="https://github.com/user-attachments/assets/627239a8-78df-4026-a791-2c7ec1ccb8b0" />


## 4. ANALYZE:
To ensure the ROP was responsive to real-word volatility, the analysis focused on four signals:
- Systemic Seasonality: Calculated unique Seasonality Indices for 500 store-item combinations.
  + Because sales of this dataset is seasonal ( the 16.7% sunday surge and 19.45% Monday lull compared to the average week sales), calculating store-item specific indices of each weekday to estimate the demand more accuracy.
- ABC Segmentation:
  + Applied Pareto analysis to 5 years of revenue data, categorizing 500 store-item combinations into tiered priority to optimize capital allocation.
- Heuristic Promotion Detection:
  + Engineered a statistical outlier detection model (Baseline + 2 σ) to identify and "flag" historical promotion dates where metadata was missing, preventing demand spikes from skewing the standard seasonality index.
- Performance Validation (Backtesting): 
  + **Methodology:** Simulated ordering cycles (weekly for normal date and daily for promotion date) by comparing forecasted ROP against actual demand over the final year of the 5-year dataset.
  + **Findings:** \
    **Normal Dates:** The seasonality-adjusted model maintained a 99% service level while achieving a 2.82% reduction in excess inventory compared to the baseline method. \
    **Promotion Dates:** The promotion ROP model maintained a 92% service level with the average excess rate at 14.91% and the average shortage rate at 3.92%. 
### Build ROP Model
**a. Seasonality-Adjusted Model**
- The formular for calculating Inventory ROP: 
<img width="1550" height="81" alt="image" src="https://github.com/user-attachments/assets/697ce8dc-80bd-43a3-9d98-ad49dc6b54cb" />

**b. Traditional Model**
- The formular for calculating Inventory ROP: 
<img width="1559" height="91" alt="image" src="https://github.com/user-attachments/assets/04763714-c377-403d-ac6e-2bc781ceafe3" />

**c. Promotion ROP**
- The formular for calculating Inventory ROP: 
<img width="1582" height="89" alt="image" src="https://github.com/user-attachments/assets/86e1b3ba-5de0-4cf5-b3f1-dff6e51de36e" />

## 5. SHARE:
#### a. Seasonality-Adjusted ROP model
- The backtest is implemented in total 26,500 weeks (across 50 items in 10 stores), there are **26,211 overstock weeks** with the **average excess rate at 20.78%** and **289 outstock weeks** with the **average shortage rate at 2.44%**.
<img width="1583" height="749" alt="image" src="https://github.com/user-attachments/assets/7ded9bda-4852-41e1-b386-b5074ee256e3" />


The seasonality-adjusted ROP model
- The Seasonality-Adjusted ROP model satisfies the **service level of 99%** which is similar to Traditional ROP model while simultaneously **reducing weekly excess inventory by 2.98%** compared to the traditional ROP method.
<img width="1585" height="650" alt="image" src="https://github.com/user-attachments/assets/4d4b00e0-bbdb-4dfa-b74f-b0db848f8daf" />

The traditional ROP model

#### b. Promotion ROP model
- The backtest is implemented in 8,115 promotion date (across 50 items in 10 stores), there are 7,669 overstock dates with the average excess rate at 13.4% and 446 outstock dates with the average shortage rate at 3.74%.
<img width="1588" height="746" alt="image" src="https://github.com/user-attachments/assets/0e23ad2f-586f-4d06-a2a7-39193747c174" />





- After backtesting Promotion ROP i decide to plus 10% Promotion ROP to cover abnormal demand surge dates. The results show that the number of outstock dates decrease significantly from 446 outstock date of old model to 34 outstock dates. The shortage rate also drop to 2.35%, however the excess rate higher than olde model approximately 10%.
<img width="1582" height="745" alt="image" src="https://github.com/user-attachments/assets/9ef69b19-3c18-4cf5-8dd5-ef5a49d017fe" />




## 4. ACT:
1. Adopt Seasonality-Adjusted ROP: Implement for entire item and store to capture immediate capital efficiency gains.
2. Tactical Promotion Buffers: Add a 10% safety margin during promotional dates to resolve the shortage risk.
# III. Dataset and Tools used: 
- Datasets:
  + [train](https://github.com/Phuctran-81/Reorder-Point-Setup-Model/releases/tag/V1.0.0) is dataset used to build the model.
  + [test](https://github.com/Phuctran-81/Reorder-Point-Setup-Model/releases/tag/V1.0.0) is dataset contained the final year data and ROP using for testing the success level.
- Database: SQL Server Management Studio 21.
- Data visualization: Access the dashboard at [Tableau Public](https://public.tableau.com/views/Book2_17765843140690/Dashboard1?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link).
