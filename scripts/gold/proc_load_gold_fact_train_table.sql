
/*
====================================================================
Insert data to gold.fact_train table
====================================================================
*/
-- cte_baseline_sd_30d calculates baseline_30d and standard_deviation_30d
WITH cte_baseline_sd_30d AS (
SELECT
	*,
-- This statement flags the promotion date as is_promotion
	CASE 
		WHEN baseline_30d + 2 * standard_deviation_30d <= sales THEN 1 ELSE 0
	END is_promotion
FROM (
	SELECT
		record_id,
		date,
		week_calendar,
		store,
		item,
		sales,
		weekday_name,
		weekday_number,
		AVG (sales) OVER (PARTITION BY store, item ORDER BY date ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING) AS baseline_30d,
		STDEV (sales) OVER (PARTITION BY store,item ORDER BY date ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING) AS standard_deviation_30d
	FROM silver.train )t
			)
---------------------------------------------
-- Insert data to gold.fact_train table
---------------------------------------------
INSERT INTO gold.fact_train 
	(
		record_id,
		seasonality_index_id,
		category_id,
		date_calendar,
		week_calendar,
		store_id,
		item_id,
		sales,
		weekday_name,
		weekday_number,
		baseline_30d,
		standard_deviation_30d,
		is_promotion
				)	
SELECT
		a.record_id,
		b.seasonality_index_id,
		c.category_id,
		a.date AS date_calendar,
		a.week_calendar,
		a.store AS store_id,
		a.item AS item_id,
		a.sales,
		a.weekday_name,
		a.weekday_number,
		a.baseline_30d,
		a.standard_deviation_30d,
		a.is_promotion
FROM cte_baseline_sd_30d a
LEFT JOIN gold.dim_seasonality_index b
		ON a.store = b.store_id AND a.item = b.item_id AND a.weekday_number = b.weekday_number
LEFT JOIN gold.dim_category c
		ON a.store = c.store_id AND a.item = c.item_id
WHERE date > DATEADD (DAY, 31, (SELECT MIN(date) FROM cte_baseline_sd_30d))
