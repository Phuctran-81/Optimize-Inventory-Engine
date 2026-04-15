# Reorder Point Setup Model
## I. OVERALL
## 1. Executive Summary
**Objective:** Engineered an automated Inventory Reorder Point (ROP) system to solve the "Overstock vs. Stock-out" paradox for 500 unique store-item combinations. By transitioning from a flat traditional model to a **Seasonally-Adjusted engine**, I successfully maintained a **99% Service Level** while reducing weekly excess inventory cost by **2.82%**.
## 2. Key Project Insights
- **High-Precision Seasonality:** Identified the differencerate in sales between weekdays and the weekly average, which traditional model miss, allowing for more accurate inventory calculations.
- **Automated Promotion Detection:** Developed a statistical outlier detection model (Basline 30day + 2 standard deviation) to flag missing promotion dates and calculate a **Promotion Lift Factor**, reducing shortage risks during high-traffic events.
- **Strategic Capital Allocation:** Implemented ABC Revenue Classification to priortize Class A items (80% of revenue), ensuring 90% daily availability for top-performers while minimizing the "carrying cost" of slow-moving stock.
- **Validated Reliability:** Conducted a rigorous 12-month backtest across 26,474 data points to prove model efficiency.
-----------------------------
## II. ANALYTICAL FRAMEWORK: A 6-STAGE DEEP DIVE
## 1. Ask
The goal of this project is to build a  model establishing inventory reorder point. The model will balance between ensuring the product availability and minizing carrying cost.
## 2. Prepare
### Data Sourcing:
The raw dataset was originally sourced from Kaggle with **913,000 rows** (Store Item Demand Forecasting Challenge). For this analysis, the data has been ingested into a SQL Server environment. This setup allows for the high-performance processing required to handle the 5-year history of daily sales across 10 stores and 50 items.
### Data Storage
A tiered strategy in MS SQL Server was used to ensure integrity:
- Bronze Layer: Contains immutable raw CSV imports as a “Single Source of Truth”.
- Silver Layer: Contains processed datasets (remove duplicate, error data, add new column ….)
- Gold Layer: Contains cleaned, validated dataset for staged analysis.
  
## 3. Process (Data Engineering & Cleaning)
<img width="810" height="431" alt="image" src="https://github.com/user-attachments/assets/ad1d22a8-d48d-4379-99fe-c259cbf1e582" />

### A. Bronze to Silver
#### Data integrity and consistency verification
Data integrity Verification: Used `COUNT(DISTINCT item)` grouped by store to ensure that no store lost product.
Data consistency Verification:
- Verifying data duplication by checking the composite key of `date` + `store` + `item` has zero duplicates, ensuring that the dataset will be accurate and not double-counted.
- Checking data errors to ensure no null values.
#### Data enrichment
New drived columns were created to unlock deeper insight:
- Temporal Feature: calculating new column such as week_calendar to enable calculate the weekly inventory, extracting weekday_name and weekday_number to enable calculate the seasonality of weekday sales, creating new column dwh_create_date to manage data daily updated.
- Primary Key: create primary_key to manage data.
### B. Silver to Gold
Create two new table gold.dim_seasonality_index and gold.dim_abc_category to optimize the performance when updating new data.
#### a. gold.dim_seasonality_index table
- Calculating the average of the ratio between weekday sales and average week sales to get seasonality index of each weekday.
- Performed ROW_NUMBER () to create primary key for this table.
#### b. gold.dim_category
- Performed Window function rolling-sum the percentage of revenue of each item at each store to cagorize the item.
- Performed ROW_NUMBER () to create primary key for this table.
##### c. Gold.fact_train
- Performed Window_function to calculate the 30 day average sales of each item at each store and the 30 day standard deviation of sales of each item at each store.
- Flagging the promotion day by detecting days where sales > 30 day average sales + 2 * 30 day standard deviation.
- Performed JOIN function to get foreign key from gold.dim_category and gold.dim_seasonality_index table.
- Finally, filter out 30 first days of each item at each store, that rows miss data to calculate the complete 30 day average sales and 30 day standard deviation.
<img width="1115" height="704" alt="image" src="https://github.com/user-attachments/assets/627239a8-78df-4026-a791-2c7ec1ccb8b0" />


## 4. ANALYZE:
### A. Build the Reorder Point Setup Model
#### a. Categorizing the store-item
**Purpose:** The primary goal of the store-item classification is to prioritize management focus and capital allocation. By segmenting my store-item, I can apply different "Service Level" targets (Z-scores) to specific categories. This strategy approach ensures high availability for critical, high-value items (Class A) while preventing over-investment in slow-moving stock (Class C). 
- I used Z = 1.3 for class A item to ensure 90% the store have enough inventory each day, Z = 0.9 for class B items to cover 81% And Z = 0.65 for class C item to cover 74%.

**Method:** I categorized the store-item by sorting store-items by revenue in descending order to calculate the running percentage of total company revenue.
- Class A (High Value): The group of items generating 80% of revenue.
- Class B (Intermediate): store-Item generating the next 15% of revenue.
- Class C (Low Value): Items generating only the final 5% of revenue.

#### b. Seasonality-Adjusted ROP Model
***Note:** To optimize the accuracy, I calculated the multipliers separately for specific item at specific store (the multipliers such as Seasonality Index, Baseline 30d, MAE).* \
Through the data exploratory analysis, I found that the sales is seasonal. Averagely, sales of monday is lower than the average week sales 19.45% while sales of saturdays and sundays are higher than the average week sales 11.8% and 16.17% respectively.\
From that result, i decided to use a formula for establishing reorder point called Seasonality-Adjusted ROP model: 

<img width="1273" height="82" alt="image" src="https://github.com/user-attachments/assets/4b2ad83f-14cd-4085-a37c-e99b11f8dc27" />

- **ROP:** The forecast Inventory per day.
- **Baseline 30d:** Average actual sales over the last 30 days
- **Seasonality Index:** Multiplier calculated by sales of each weekday divided by average week sales then average the rate.
- **Z:** The distance measured by Standard Deviation from the mean of the distribution.
- **MAE:** The average error between Actual Sales and Forecast ROP over the last 30 days.
#### c. Traditional ROP Model
***Note:** To optimize the accuracy, I calculated the multipliers separately for specific item at specific store (the multipliers such as Baseline 30d, Standard Deviation 30d).* \
Moreover, i also calculated the rop based on the formular called traditional ROP model: 

<img width="1172" height="68" alt="image" src="https://github.com/user-attachments/assets/e5ec7d58-0b31-441a-8b69-345be0aceecc" />

- **ROP:** The forecast Inventory per day.
- **Baseline 30d:** Average actual sales over the last 30 days
- **Z:** The distance measured by Standard Deviation from the mean of the distribution.
- **Standard Deviation 30d:** The average deviation of values compared to the mean of the distribution over the last 30 days.
#### d. Promotion ROP model
***Note:** To optimize the accuracy, I calculated the multipliers separately for specific item at specific store (the multipliers such as Lift%, Baseline 30d, Standard Deviation 30d, MAE).* 
#### d.1 Flagging Promotion Date
**Purpose:** Because this dataset missing data about promotion date, i detected extreme outlier point and assigned it as a promotion date to make the forecast model more precisely. \
**Method:** The logic for flagging promotion date is that if actual sales is bigger than the average actual sales over the last 30 days + 2 (z score) Standard Deviation (just 2.7% probability the values fall in this range) this is promotion date.
<img width="1375" height="87" alt="image" src="https://github.com/user-attachments/assets/4ed283aa-65c0-42ea-90cc-2fc34c60a13c" />
- **Actual Sales:** The actual sales of item.
- **Baseline 30d:** The average actual sales over the last 30 days.
- **Standard Deviation 30d:** The average deviation of values compared to the mean of the distribution over the last 30 days.
#### d.2 Promotion Lift Factor
**Purpose:** To quantify the actual increase in sales volume during promotional events versus the standard 30-day baseline, ensuring future stock levels are optimized for high-traffic days. \
**Method:** Lift factor is calculated by the following formula:
<img width="1308" height="135" alt="image" src="https://github.com/user-attachments/assets/c417e253-6d9c-4698-9b6e-5ebbb8de5cb4" />
- **Lift%**: Lift factor.
- **Actual Sales:** The actual sales of specific item at specific store on promotion date.
- **Baseline 30d:** The average actual sales over the last 30 days.
- **n:** Total promotion days of specific item at specific store. *( I used n = 6 to calculated the average lift factor in the last 6 promotion date).*

#### d.3 Promotion ROP Model
After calculating Lift factor, i used the following formula for establishing Promotion ROP: 
<img width="1041" height="66" alt="image" src="https://github.com/user-attachments/assets/cb3b8354-ad4e-4982-b651-7260453f90ea" />
- **ROP:** The forecast Inventory per promotion day.
- **Baseline 30d:** The average actual sales over the last 30 days.
- **Lift% :** Lift factor
- **Z:** The distance measured by Standard Deviation from the mean of the distribution.
- **MAE:** The average error between Actual Sales and Forecast ROP.

#### B. Success Level Backtesting
**Purpose:** Validate the reliability of the **Seasonality-Adjusted Reorder Point (ROP)** model against historical demand and compare its efficiency to the traditional ROP model. 

**Methodology:**
- **Backtest Duration:** the last 12-month data of dataset.
- **Scope:** 50 items across 10 stores (500 unique item-store).
- **Logic:** Simulated weekly ordering cucles by comparing forecasted ROP against actual weekly demand over the final year of the 5-year dataset.
## 5. SHARE:
#### a. Seasonality-Adjusted ROP model
- The backtest is implemented in total 26,474 weeks (across 50 items in 10 stores), there are **26,275 overstock weeks** with the **average excess rate at 21.77%** and **199 outstock weeks** with the **average shortage rate at 2.07%**. 
- The Seasonality-Adjusted ROP model satisfies the **service level of 99%** which is similar to Traditional ROP model while simultaneously **reducing weekly excess inventory by 2.82%** compared to the traditional ROP method.
#### b. Promotion ROP model
- The backtest is implemented in 7,321 promotion date (across 50 items in 10 stores), there are 6,799 overstock dates with the average excess rate at 14.91% and 522 outstock dates with the average shortage rate at 3.92%.
## 4. ACT:
#### a. Adopting the Seasonality-Adjusted ROP model for inventory planning.
By applying category-specific safety stock levels, we can prioritize availability for high-performance items while minimizing carrying costs for slower-moving stock.
#### b. Adopting store-item specific lift factor
By applying store-item specific lift factor for calculating ROP and adding 10% tactical safety buffer, this can help mitigate the risk of abnormal demand surges, specifically addressing the current 3.92% shortage rate observed during previous promotions.
