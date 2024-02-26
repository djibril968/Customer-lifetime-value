USE Projects_01

SELECT * FROM superstore_01


/*
Data cleaning

here we rename columns we need before extraction
*/

SP_RENAME 'Superstore_01.[Country Region]', 'Country', 'COLUMN'
SP_RENAME 'Superstore_01.[Order date]', 'Order_date', 'COLUMN';
SP_RENAME 'Superstore_01.[Order ID]', 'Order_ID', 'COLUMN';
SP_RENAME 'Superstore_01.[Customer Name]', 'Customer_Name', 'COLUMN';

ALTER TABLE Superstore_01
ALTER COLUMN Order_date DATE

---Now we view the required columns
SELECT Order_date, 
		Order_ID,
		Customer_Name
		,Sales
FROM Superstore_01

---now we create a new table using the extracted data

SELECT Order_date 
		,YEAR([Order_Date]) AS Order_year
		,MONTH(Order_Date) AS Order_Month
		,FORMAT(Order_Date, 'MMMM') AS Order_Month_
		,CEILING(MONTH(Order_date) / 3.0) AS Order_Qtr ---since sql server doesn't have the QUARTER function we divide the month number by 3 and use the ceiling function to round up
		,FORMAT(Order_date, 'yyyy-MM') AS year_month
		,CONCAT(YEAR(Order_date), '-', CEILING(MONTH(Order_date) / 3.0)) AS Year_Qtr
		,Order_ID
		,Customer_Name
		,Sales
INTO Cohort_tbl
FROM Superstore_01

---now that we have successfully extracted the data we need, we go ahead with our analysis
---create a month based cohort group

SELECT Customer_Name
		,MIN(Order_date) AS Initial_Pur ---This gives the first date the customer initiated a purchase
		,DATEFROMPARTS(YEAR(MIN(Order_date)), MONTH(MIN(Order_date)), 1) AS cohort_date ---This gives the year and month of the first purchase
INTO  Cohort_02
FROM Cohort_tbl
GROUP BY Customer_Name
ORDER BY 2, 3

----lets get the cohort by quarter

SELECT Customer_Name
		,MIN(Order_date) AS Initial_pur_date
		,MIN(CEILING(MONTH(Order_date) / 3.0)) AS Initial_Pur_Qtr
		,DATEFROMPARTS(YEAR(MIN(Order_Date)), MIN(CEILING(MONTH(Order_date) / 3.0)), 1) AS Ini_pur_qtr
FROM Cohort_tbl
GROUP BY Customer_Name
ORDER BY 2, 3

----next we create the cohort index
/*
this is an integer that represents the duration between the initial and subsequent purchase date for each customer
*/
SELECT s.Order_date
		,s.Customer_Name
		,c.cohort_date
		,YEAR(s.Order_date) AS Order_year
		,MONTH(s.Order_date) AS Order_month
		,YEAR(c.Initial_pur) AS Cohort_year
		,MONTH(c.Initial_pur) AS Cohort_month
FROM Superstore_01 s
LEFT JOIN Cohort_02 c
ON s.Customer_Name = c.Customer_Name
ORDER BY 1, 3


---To create cohort index
SELECT ccc.*
		, cohort_index = year_diff * 12 + month_diff + 1
INTO cohort_ret_mon
FROM
(
		SELECT	cc.*,
				year_diff = Order_year - Cohort_year
				,month_diff = Order_month - Cohort_month
		
		FROM
		(
				SELECT s.Order_date
						,s.Customer_Name
						,c.cohort_date
						,YEAR(s.Order_date) AS Order_year -----this gives the value for the order year for indivdual purchases made by customers
						,MONTH(s.Order_date) AS Order_month ----- this gives the value for the order month for individual purchases, it is extracted from the order date
						,YEAR(c.cohort_date) AS Cohort_year ----- this gives the value for the year of first purchase made by customers
						,MONTH(c.cohort_date) AS Cohort_month ---- this gives the value for the month of first purchase made by customers. its is extracted from the order date
						,(CONCAT(YEAR(c.cohort_date), '-', CAST(MONTH(c.cohort_date) AS INT))) AS year_month
				FROM Superstore_01 s
				LEFT JOIN Cohort_02 c
				ON s.Customer_Name = c.Customer_Name
		)cc

) ccc
ORDER BY 1, 8;

SELECT *
FROM
(
	SELECT DISTINCT
			Customer_Name
			,cohort_date
			,cohort_index
	FROM cohort_ret_mon
	----ORDER BY 1, 3
	
) tt

PIVOT(
		COUNT(Customer_Name)
		for cohort_index in 
		(	[1], [2], [3], [4], [5] 
			,[6], [7], [8], [9], [10]
			,[11], [12], [13], [14], [15]
			,[16], [17], [18], [19], [20] 
			,[21], [22], [23], [24], [25] 
			,[26], [27], [28], [29], [30]
			,[31], [32], [33], [34], [35] 
			,[36], [37], [38], [39], [40]
			,[41], [42], [43], [44], [45] 
			,[46], [47], [48]
		) 
)	AS pivot_table_mon


---let create cohort for each quarter


SELECT qq.*
		,cohort_index = year_diff * 4 + qtr_diff + 1 ---since we are looking at quarterly acquisition of customers, we will multiply by 4 since there are 4 quarters in a year
INTO cohort_retention_qtrr
FROM 
		(
		SELECT
				q.*
				,q.Order_year - q.Cohort_year AS year_diff
				,q. Order_qtr - q.Cohort_qtr AS qtr_diff
		FROM
				(
				SELECT s.Order_date,
						s.Customer_Name
						,c.Initial_pur
						,YEAR(s.order_date) AS Order_year
						,CEILING(MONTH(Order_date)/ 3.0) AS Order_qtr
						,YEAR(c.Initial_pur) AS Cohort_year
						,CEILING(MONTH(c.Initial_pur)/ 3.0) AS Cohort_qtr
						,CONCAT(YEAR(c.Initial_pur), '-', 'Q', CEILING(MONTH(c.Initial_pur)/3.0)) AS cohort_year_qtr
				FROM Superstore_01 s
								LEFT JOIN Cohort_02 c
								ON s.Customer_Name = c.Customer_Name
				) q
		)qq

	

	SELECT *
	FROM (
		SELECT DISTINCT
				Customer_Name
				,cohort_year_qtr
				,cohort_index
		FROM cohort_retention_qtrr
	) tt
	PIVOT(
			COUNT(Customer_Name)
			for cohort_index in 
			(	[1], [2], [3], [4], [5] 
				,[6], [7], [8], [9], [10]
				,[11], [12], [13], [14], [15]
				,[16] ) 
	)	AS pivot_tbl