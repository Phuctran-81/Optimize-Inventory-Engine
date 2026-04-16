/*
===========================================================
CREATE TABLE gold.fact_train table
===========================================================
*/
CREATE TABLE gold.fact_train 
			(
				record_id INT,
				seasonality_index_id INT,
				category_id INT,
				date_calendar DATE,
				week_calendar DATE,
				store_id INT,
				item_id INT,
				sales INT,
				weekday_name NVARCHAR(50),
				weekday_number INT,
				baseline_30d FLOAT,
				standard_deviation_30d FLOAT,
				is_promotion INT,
				dwh_create_date DATETIME2 DEFAULT GETDATE()
				-- Create dwh_create_date is to manage updated new rows.
						);
GO

/*
===========================================================
CREATE TABLE gold.dim_seasonality_index table
===========================================================
*/
CREATE TABLE gold.dim_seasonality_index 
			(	
				seasonality_index_id INT,
				store_id INT,
				item_id INT,
				weekday_number INT,
				weekday_name NVARCHAR(50),
				seasonality_index FLOAT
						);
GO

/*
===========================================================
CREATE TABLE gold.dim_category
===========================================================
*/
CREATE TABLE gold.dim_category 
			(
				category_id INT,
				store_id INT,
				item_id INT,
				running_pct FLOAT,
				abc_category NVARCHAR (10)
						);
