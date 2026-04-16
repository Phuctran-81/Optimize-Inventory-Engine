-- This cte calculates the ROP
WITH cte_setup_rop AS (
SELECT
  	a.record_id,
  	a.date_calendar,
  	a.week_calendar,
  	a.store_id,
  	a.item_Id,
  	a.sales,
  	a.weekday_number,
  	c.abc_category,
  	CASE 
  		WHEN abc_category = 'A' THEN baseline_30d + 1.3 * standard_deviation_30d
  		WHEN abc_category = 'B' THEN baseline_30d + 0.9 * standard_deviation_30d
  		WHEN abc_category = 'C' THEN baseline_30d + 0.65 * standard_deviation_30d
  	END AS old_rop,
  	CASE 
  		WHEN abc_category = 'A' THEN baseline_30d * b.seasonality_index + 1.625 * AVG (ABS(baseline_30d * seasonality_index - sales)) 
  								OVER (PARTITION BY a.store_id, a.item_Id ORDER BY a.date_calendar ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING)
  		WHEN abc_category = 'B' THEN baseline_30d * b.seasonality_index + 1.125 * AVG (ABS(baseline_30d * seasonality_index - sales)) 
  								OVER (PARTITION BY a.store_id, a.item_Id ORDER BY a.date_calendar ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING)
  		WHEN abc_category = 'C' THEN baseline_30d * b.seasonality_index + 0.81 * AVG (ABS(baseline_30d * seasonality_index - sales)) 
  								OVER (PARTITION BY a.store_id, a.item_Id ORDER BY a.date_calendar ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING)
  	END AS new_rop,
  	is_promotion
FROM gold.fact_train a
LEFT JOIN gold.dim_seasonality_index b
ON a.seasonality_index_id = b.seasonality_index_id
LEFT JOIN gold.dim_category c
ON a.category_id = c.category_id
			)
--------------------------------------------
Backtesting Weekly ROP
--------------------------------------------
SELECT 
		SUM (CASE WHEN weekly_old_rop > weekly_actual_sales THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS old_success_rate,
		SUM (CASE WHEN weekly_new_rop > weekly_actual_sales THEN 1 ELSE 0 END) * 100.0 / COUNT (*) AS new_success_rate,
		AVG(CASE WHEN weekly_old_rop > weekly_actual_sales THEN (weekly_old_rop/weekly_actual_sales-1) * 100 END) AS old_excess_rate,
		AVG(CASE WHEN weekly_old_rop < weekly_actual_sales THEN (weekly_old_rop/weekly_actual_sales-1) * 100 END) AS old_shortage_rate,
		AVG(CASE WHEN weekly_new_rop > weekly_actual_sales THEN (weekly_new_rop/weekly_actual_sales-1) * 100 END) AS new_excess_rate,
		AVG(CASE WHEN weekly_new_rop < weekly_actual_sales THEN (weekly_new_rop/weekly_actual_sales-1) * 100 END) AS new_shortage_rate
FROM (
		SELECT 
			week_calendar,
			store_id,
			item_id,
			abc_category,
			SUM (old_rop) AS weekly_old_rop,
			SUM (new_rop) AS weekly_new_rop,
			SUM (sales) AS weekly_actual_sales
		FROM cte_setup_rop
		WHERE date_calendar > DATEADD (MONTH, -12, (SELECT MAX(date_calendar) FROM cte_setup_rop)) AND is_promotion = 0
		GROUP BY store_id, item_id, week_calendar
					) AS success_rate 
