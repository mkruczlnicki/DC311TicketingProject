--The below queries were created throughout my General Assembly Data Analytics course. These queries were used in and out of class as practice and skills training.
--These are queries made on the commonly-used Superstore data set. A copy of the data can be found here: https://www.kaggle.com/datasets/bravehart101/sample-supermarket-dataset

--How many orders are missing zip/postal codes by region?
SELECT reg.region, COUNT(*)
FROM orders o
	LEFT JOIN regions reg ON o.region_id = reg.region_id
WHERE o.postal_code IS NULL
GROUP BY region
;

--How many of our orders are from the United States and missing zip/postal codes by region?
SELECT COUNT(*) AS count_of_entries
FROM orders o
	LEFT JOIN regions reg USING(region_id)
WHERE o.postal_code IS NULL AND reg.country = 'United States'
;

--String positions and substrings
SELECT product_name
	,STRPOS(product_name,',')
FROM products;
--Above creates a column which tells you when the comma occurs. Now let's break it at the comma
SELECT SUBSTRING(product_name,1,STRPOS(product_name,',')-1)
FROM products
WHERE STRPOS(product_name,',')>0
;
--Above looks at product name, creates 1 column, and stops at the character count set by STRPOS
--Need to add a -1 because you want the comma removed, so you want 1 less
--The above will send an error if there's NULL value, so add a WHERE to remove

--Category name in all caps
SELECT UPPER(category) AS upper_category
FROM products;
--Combine “sub_category field” with its “product_name” field as a “new_name” field and print the length of the new name field
SELECT CONCAT(sub_category,product_name)
	,LENGTH(CONCAT(sub_category,product_name)) AS new_name
FROM products;
--First five characters of the product_id without hyphens or blank spaces
SELECT product_id
	,LEFT(REPLACE(product_id,'-',''),5) AS alt_id
FROM products
LIMIT 5
;
--Combined effect of above fields
SELECT
	UPPER(category) AS upper_category
	,CONCAT(sub_category,product_name)
	,LENGTH(CONCAT(sub_category,product_name)) AS new_name
	,LEFT(REPLACE(product_id,'-',''),5) AS sub_product_id_alt
FROM products
;

--How many orders containing recycled products were sold to customers in the Consumer segment?
SELECT COUNT(*)
FROM orders o
	LEFT JOIN products p ON o.product_id=p.product_id
	LEFT JOIN customers c ON o.customer_id=c.customer_id
WHERE p.product_name ILIKE '%recycled%' 
	AND c.segment = 'Consumer'
;

--Your VP of Operations wants to identify the product ids of products returned without a given reason. Use a Right Join. 
SELECT o.product_id
	,r.reason_returned
	,date_part('year',o.order_date) AS order_year
FROM orders o
	RIGHT JOIN returns r ON o.order_id=r.order_id
WHERE r.reason_returned = 'Not Given'
	AND date_part('year',o.order_date)=2020
;

--Your VP of Operations wants to identify the DISTINCT product ids of products returned without a given reason. Use a Right Join. 
SELECT DISTINCT o.product_id
	,r.reason_returned
	,date_part('year',o.order_date) AS order_year
FROM orders o
	RIGHT JOIN returns r ON o.order_id=r.order_id
WHERE r.reason_returned = 'Not Given'
	AND date_part('year',o.order_date)=2020
;

-- Find a list of all Furtniture products sold excluding the year 2020
SELECT product_id
FROM products
WHERE category = 'Furniture'
EXCEPT
SELECT product_id
FROM orders
WHERE DATE_PART('year',order_date) = '2020'
;

--Return all of the products and all regions together
SELECT *
FROM products
	CROSS JOIN regions
LIMIT 1000
;

-- Look at the number of sales each salesperson made based on orders that were NOT returned
SELECT COUNT(*)
	,reg.salesperson
FROM orders o
	JOIN regions reg ON o.region_id=reg.region_id
	--JOIN the regions to orders so that you filter out any of the orders without an assigned salesperson
	LEFT JOIN returns ret on o.order_id=ret.order_id
	--LEFT JOIN because we want to know all of the returned and not returned items so we can use WHERE below
WHERE ret.order_id IS NULL
GROUP BY 2
ORDER BY 1 DESC
;

--Avoiding zeros in division calcuations to avoid errors
--Option 1
SELECT product_id
	,quantity/NULLIF(discount,0) AS discount_per_item
FROM orders
WHERE ship_mode = 'Standard Class';
--Option 2 - Tip - Add the divided quantities to the Select query so you can visually check to make sure your equation worked
SELECT product_id
	,quantity
	,discount
	CASE
		WHEN discount=0 THEN NULL
		WHEN discount>0 THEN quantity/discount
	END AS discount_per_item
FROM orders
;

--We want to see all of the information we can get on customers who made orders in 2020
SELECT *
FROM orders o
	FULL OUTER JOIN customers c ON o.customer_id=c.customer_id
WHERE DATE_PART('year',o.order_date)='2020'
;

--Number of orders that occurred on July 4th
SELECT 
	order_date
	--This is rolling the date up to the day field b/c it might have a time, or less specific date
	,TO_CHAR(DATE_TRUNC('day',order_date),'YYYY-MM-DD') AS day
	,COUNT(*)
FROM orders
--Since the date is already rounded to the date, this filter is shorter
WHERE TO_CHAR(DATE_TRUNC('day',order_date),'MM-DD') = '07-04'
GROUP BY 1
;

--Number of orders between Memorial Day and Labor Day 2019
SELECT 
	COUNT(*) AS order_num
FROM orders
WHERE order_date BETWEEN '2019-05-27' AND '2019-09-04'
;

--Subquery - FROM
--Have we seen an increase in average monthly sales over time?
--Query 1: We need the total number of sales first.
SELECT DATE_TRUNC('month',order_date) AS order_month
	,SUM(sales) AS monthly_sales
FROM orders
GROUP BY 1
--Query 2: We need to average out the sales total
SELECT DATE_PART('year',order_month) AS year,
	ROUND(AVG(monthly_sales),2) as avg_monthly_sales
FROM(
	SELECT DATE_TRUNC('month',order_date) AS order_month
		,SUM(sales) AS monthly_sales
	FROM orders
	GROUP BY 1
	) AS temp
GROUP BY 1
;

--Most customers make several hundred purchases from us. How much of the revenue is made up by the below segmentation of buyers
--Inner Query: Categorize customers by purchase frequency and calculate total sales per customer. ID, Sales Count, Case
SELECT customer_id
	,COUNT(*) AS sales_count
	--Little unclear of why we need the sum
	,SUM(sales) as sales
	,CASE
		WHEN COUNT(*) > 1000 THEN 'Supplier'
		WHEN COUNT(*) > 100 THEN 'Frequent'
		ELSE 'All others'
	END AS purchase_frequency
FROM orders
GROUP BY 1
;

--Outer query: How much in sales did each segment make?
SELECT purchase_frequency
	,SUM(sales)
FROM
(
SELECT customer_id
	,COUNT(*) AS sales_count
		--You are going to need to sum the sales in this because if you don't, it effectively doesn't exist in the sub-table, so if you want to gather 
	,SUM(sales) AS sales
	,CASE
		WHEN COUNT(*) > 1000 THEN 'Supplier'
		WHEN COUNT(*) > 100 THEN 'Frequent'
		ELSE 'All others'
	END AS purchase_frequency
FROM orders
GROUP BY 1
) AS Temp
GROUP BY 1
;

--Subquery with IN - can only have 1 column
SELECT product_id
FROM products
WHERE CAST(product_cost_to_consumer AS int)>500
--Outer query: Look at the 1 column in inner query and give me the count
SELECT COUNT(*)
FROM orders
WHERE product_id 
IN
(
SELECT product_id
FROM products
WHERE CAST(product_cost_to_consumer AS int)>500)
;

--How many orders have more profit than the average product 
SELECT COUNT(*)
FROM orders
WHERE CAST(profit AS int) > 
	(SELECT AVG(profit) FROM orders)
	;
