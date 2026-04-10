# Reorder Point Setup Model
## I. OVERALL
## 1. PROBLEM:
The goal of this project is to building a  model establishing inventory reorder point. The model will balance between ensuring the product availability and minizing carrying cost.
## 2. ACTIONS:
### A. Build the Reorder Point Setup Model
#### a. Categorizing the store-item
**Purpose:** The primary goal of the store-item classification is to prioritize management focus and capital allocation. By segmenting my store-item, I can apply different "Service Level" targets (Z-scores) to specific categories. This strategy approach ensures high availability for critical, high-value items (Class A) while preventing over-investment in slow-moving stock (Class C). 
- I used Z = 1.5 for class A item to ensure 93% the store have enough inventory each day, Z = 1 for class B items to cover 84% And Z = 0.8 for class C item to cover 79%.

**Method:** I categorized the store-item by sorting store-items by revenue in descending order to calculate the running percentage of total company revenue.
- Class A (High Value): The group of items generating 80% of revenue.
- Class B (Intermediate): store-Item generating the next 15% of revenue.
- Class C (Low Value): Items generating only the final 5% of revenue.

#### b. Seasonality-Adjusted ROP Model
***Note:** To optimize the accuracy, I calculated the multipliers separately for specific item at specific store (the multipliers such as Seasonality Index, Baseline 30d, MAE).* \
Through the data exploratory analysis, I found that the sales is seasonal. Averagely, sales of monday is lower than the average week sales 20.84% while sales of saturdays and mondays are higher than the average week sales 12.46% and 18.40% respectively.\
From that result, i decided to use a formula for establishing reorder point called Seasonality-Adjusted ROP model: \
`ROP = (Baseline 30d * Seasinality Index) + (Z * 1.25 * MAE) `
<img width="1273" height="82" alt="image" src="https://github.com/user-attachments/assets/4b2ad83f-14cd-4085-a37c-e99b11f8dc27" />


- **ROP:** The forecast Inventory per day.
- **Baseline 30d:** Average actual sales over the last 30 days
- **Seasonality Index:** Multiplier calculated by sales of each weekday divided by average week sales then average the rate.
- **Z:** The distance measured by Standard Deviation from the mean of the distribution.
- **MAE:** The average error between Actual Sales and Forecast ROP over the last 30 days.
#### c. Traditional ROP Model
***Note:** To optimize the accuracy, I calculated the multipliers separately for specific item at specific store (the multipliers such as Baseline 30d, Standard Deviation 30d).*
Moreover, i also calculated the rop based on the formular called traditional ROP model: \
`ROP = Baseline 30d + Z * (Standard Deviation 30d)`
<img width="1172" height="68" alt="image" src="https://github.com/user-attachments/assets/e5ec7d58-0b31-441a-8b69-345be0aceecc" />




- **ROP:** The forecast Inventory per day.
- **Baseline 30d:** Average actual sales over the last 30 days
- **Z:** The distance measured by Standard Deviation from the mean of the distribution.
- **Standard Deviation 30d:** The average deviation of values compared to the mean of the distribution over the last 30 days.
#### d. Promotion ROP model
***Note:** To optimize the accuracy, I calculated the multipliers separately for specific item at specific store (the multipliers such as Lift%, Baseline 30d, Standard Deviation 30d, MAE).* \
#### d.1 Flagging Promotion Date
**Purpose:** Because this dataset missing data about promotion date, i detected extreme outlier point to make the forecast model more precisely. \
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
After calculating Lift factor, i use the following formula for establishing Promotion ROP: 
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
## 3. RESULTS:
#### a. Seasonality-Adjusted ROP model
- The backtest is implemented in total 26,474 weeks (across 50 items in 10 stores), there are **26,245 overstock weeks** with the **average excess rate at 20.39%** and **229 outstock weeks** with the **average shortage rate at 2.24%**. 
- The Seasonality-Adjusted ROP model satisfies the **service level of 99%** which is similar to Traditional ROP model while simultaneously **reducing weekly excess inventory by 13%** compared to the traditional ROP method.
#### b. Promotion ROP model
- The backtest is implemented in 7,321 promotion date (across 50 items in 10 stores), there are 6,799 overstock dates with the average excess rate at 14.91% and 522 outstock dates with the average shortage rate at 3.92%.
## 4. RECOMMENDATIONS:
#### a. Adopting the Seasonality-Adjusted ROP model for inventory planning.
By applying category-specific safety stock levels, we can prioritize availability for high-performance items while minimizing carrying costs for slower-moving stock.
#### b. Adopting store-item specific lift factor
By applying store-item specific lift factor for calculating ROP and adding 10% tactical safety buffer, this can help mitigate the risk of abnormal demand surges, specifically addressing the current 3.92% shortage rate observed during previous promotions.
