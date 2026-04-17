INSERT INTO silver.train (
            		record_id,
            		date,
            		week_calendar,
            		store,
            		item,
            		sales,
            		weekday_name,
            		weekday_number
			              )
SELECT
  	ROW_NUMBER () OVER (ORDER BY date, store, item) AS record_id,
  	date,
  	CASE WHEN DATENAME (weekday, date) = 'Sunday' THEN DATEADD (DAY, -6, DATETRUNC(week, date))
  		ELSE DATEADD (day, 1, DATETRUNC(week,date))
  	END AS week_calendar, 
  	store,
  	item,
  	sales, 
  	DATENAME (weekday, date) AS weekday_name,
  	DATEPART (weekday,date) AS weekday_number
FROM bronze.train
WHERE sales != 0   ;
GO

-- This compresses the data and changes the storage from Rowstore to Columnstore
CREATE CLUSTERED COLUMNSTORE INDEX cci_silver_train2
ON silver.train
ORDER (date);
