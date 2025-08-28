--EDA

SELECT * FROM customers;
SELECT * FROM restaurants;
SELECT * FROM orders;
SELECT * FROM riders;
SELECT * FROM deliveries;


--Importing datasets 

-- ------------------
-- Analysis & Reports
-- ------------------

--Q1. Write a query to find the top 5 most frequently ordered dishes by customer called "Arjun Mehta" in the last 1 year.
 
SELECT customer_name,
       dishes,
	   total_orders
FROM 
(
SELECT c.customer_id,
        c.customer_name,
	    o.order_item AS dishes,
	    COUNT(*) AS total_orders,
	    DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS rank
FROM orders AS o
JOIN customers AS c
ON o.customer_id = c.customer_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '2 Year'
AND   c.customer_name = 'Arjun Mehta'
GROUP BY 1, 2, 3
ORDER BY 1, 4 DESC) AS t1
WHERE rank <= 5;


--Q2. Popular Time Slots:
-- Identify the time slots during which the most orders are placed. based on 2-hour intervals.

-- Approach 1
SELECT 
	FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 as start_time,
	FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 + 2 as end_time,
	COUNT(*) as total_orders
FROM orders
GROUP BY 1, 2
ORDER BY 3 DESC;

--Approach - 2
SELECT 
      CASE 
	      WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
          WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
          WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
		  WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
		  WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
		  WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
		  WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
		  WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
		  WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
		  WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
		  WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
		  WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00 - 00:00'
      END AS time_slot,
COUNT(order_id) AS order_count	   
FROM orders 
GROUP BY 1
ORDER BY 2 DESC;


--Q3. Order Value Analysis:
-- Find the average order value per customer who has placed more than 750 orders. -- Return customer_name, and aov(average order value

SELECT c.customer_name, 
       ROUND(AVG(total_amount):: numeric, 2) AS aov
FROM orders AS o
JOIN customers AS c
ON o.customer_id = c.customer_id
GROUP BY 1
HAVING COUNT(order_id) > 750;


--Q4. High-Value Customers:
-- List the customers who have spent more than 100K in total on food orders. -- return customer_name, and customer_id!

SELECT c.customer_id,
       c.customer_name,
       ROUND(SUM(total_amount):: numeric, 2) AS total_spent
FROM orders AS o
JOIN customers AS c
ON o.customer_id = c.customer_id
GROUP BY 1, 2
HAVING SUM(total_amount) > 100000;


--Q5. Orders Without Delivery:
-- Write a query to find orders that were placed but not delivered. -- Return each restuarant name, city and number of not delivered orders

SELECT r.restaurant_name,
       r.city,
	   COUNT(o.order_id) AS not_delivered
FROM orders AS o
LEFT JOIN restaurants AS r
ON r.restaurant_id = o.restaurant_id
LEFT JOIN deliveries AS d
ON o.order_id = d.order_id
WHERE d.delivery_id IS NULL 
GROUP BY 1, 2
ORDER BY 2 DESC;


--Q6. Restaurant Revenue Ranking:
-- Rank restaurants by their total revenue from the last year, including their name, -- total revenue, and rank within their city.

WITH ranking_table 
AS 
(
SELECT r.restaurant_name, 
       r.city,
	   SUM(o.total_amount) AS revenue,
	   EXTRACT(YEAR FROM order_date) AS last_year, 
	   RANK() OVER(PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS rank
FROM orders AS o
JOIN restaurants AS r
ON o.restaurant_id = r.restaurant_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '2 year'
GROUP BY 1, 2, 4
)
SELECT *
FROM ranking_table 
WHERE rank = 1;


--Q7. Most Popular Dish by City:
-- Identify the most popular dish in each city based on the number of orders.

SELECT * 
FROM 
(
SELECT r.city, 
       o.order_item, 
	   COUNT(order_id) AS total_orders,
	   RANK() OVER(PARTITION BY r.city ORDER BY COUNT(order_id) DESC) AS rank
FROM orders AS o
JOIN restaurants AS r
ON o.restaurant_id = r.restaurant_id
GROUP BY 1, 2
) AS t1 
WHERE rank = 1;


--Q8. Customer Churn:
-- Find customers who haven’t placed an order in 2024 but did in 2023.

SELECT DISTINCT customer_id 
FROM orders 
WHERE EXTRACT(YEAR FROM order_date) = 2023
      AND 
	  customer_id NOT IN
	                     (SELECT DISTINCT customer_id
						   FROM orders
						   WHERE EXTRACT(YEAR FROM order_date) = 2024);


--Q9. Cancellation Rate Comparison:
-- Calculate and compare the order cancellation rate for each restaurant between the -- current year and the previous year. 

WITH cancel_ratio_2023
AS
(
SELECT o.restaurant_id, 
       COUNT(o.order_id) AS total_orders, 
	   COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
FROM orders AS o
LEFT JOIN deliveries AS d
ON o.order_id = d.order_id
WHERE EXTRACT(YEAR FROM order_date) = 2023
GROUP BY 1
), 

cancel_ratio_2024
AS
(
SELECT o.restaurant_id, 
       COUNT(o.order_id) AS total_orders, 
	   COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
FROM orders AS o
LEFT JOIN deliveries AS d
ON o.order_id = d.order_id
WHERE EXTRACT(YEAR FROM order_date) = 2024
GROUP BY 1
),

last_year_data
AS
(
SELECT restaurant_id, 
       total_orders, 
	   not_delivered,
	   ROUND(
	   not_delivered:: numeric / total_orders:: numeric * 100, 
	   2) AS cancellation_rate
FROM cancel_ratio_2023
), 

current_year_data
AS
(
SELECT restaurant_id, 
       total_orders, 
	   not_delivered,
	   ROUND(
	   not_delivered:: numeric / total_orders:: numeric * 100, 
	   2) AS cancellation_rate
FROM cancel_ratio_2024
)

SELECT c.restaurant_id, 
       c.cancellation_rate AS current_year_cancel_ratio,
	   l.cancellation_rate AS last_year_cancel_ratio
FROM current_year_data AS c
JOIN last_year_data AS l
ON c.restaurant_id = l.restaurant_id;


--Q10. Rider Average Delivery Time:
-- Determine each rider's average delivery time.

SELECT o.order_id,
       o.order_time,
	   d.delivery_time,
       rider_id, 
       d.delivery_time - o.order_time AS time_difference, 
	   EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + 
	   CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' 
	   ELSE INTERVAL '0 day' END))/60 AS time_difference_sec
FROM orders AS o
JOIN deliveries as d 
ON o.order_id = d.order_id 
WHERE d.delivery_status = 'Delivered'; 


--Q11. Monthly Restaurant Growth Ratio:
-- Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining

WITH growth_ratio
AS
(
SELECT o.restaurant_id,
	   TO_CHAR(o.order_date, 'mm-yy') AS month, 
	   COUNT(o.order_id) AS current_month_orders,
	   LAG(COUNT(o.order_id), 1) OVER(PARTITION BY o.restaurant_id ORDER BY TO_CHAR(o.order_date, 'mm-yy')) AS prev_month_orders
FROM orders AS o
JOIN deliveries AS d
ON o.order_id = d.order_id 
WHERE d.delivery_status = 'Delivered'
GROUP BY 1, 2
ORDER BY 1, 2
)
SELECT restaurant_id, 
       month,
	   current_month_orders,
	   prev_month_orders,
	   ROUND((current_month_orders::numeric - prev_month_orders::numeric)/prev_month_orders::numeric * 100, 2) AS growth_ratio 
FROM growth_ratio;


--Q12. Customer Segmentation:
-- Customer Segmentation: Segment customers into 'Gold' or 'Silver' groups based on their total spending 
-- compared to the average order value (AOV). If a customer's total spending exceeds the AOV,
-- label them as 'Gold'; otherwise, label them as 'Silver'. Write an SQL query to determine each segment's 
-- total number of orders and total revenue

SELECT customer_segments, 
       SUM(total_orders) AS total_orders,
       SUM(total_spending) AS total_revenue 
FROM 	   

(SELECT customer_id,
       SUM(total_amount) AS total_spending,
	   COUNT(order_id) AS total_orders,
	   CASE  
	       WHEN SUM(total_amount) > AVG(total_amount) THEN 'Gold' ELSE 'Silver' 
	   END AS customer_segments	   
FROM orders  	
GROUP BY 1
) AS t1
GROUP BY 1;


--Q13. Rider Monthly Earnings:
-- Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.

SELECT d.rider_id, 
       TO_CHAR(o.order_date, 'mm-yy') AS month,
       SUM(total_amount) AS revenue, 
	   ROUND(SUM(total_amount):: numeric * 0.08, 2) AS riders_earning
FROM orders AS o
JOIN deliveries AS d
ON o.order_id = d.order_id
GROUP BY 1, 2
ORDER BY 1, 2;


--Q14. Rider Ratings Analysis:
-- Find the number of 5-star, 4-star, and 3-star ratings each rider has. 
-- riders receive this rating based on delivery time. 
-- If orders are delivered less than 15 minutes of order received time the rider get 5 star rating, 
-- if they deliver 15 and 20 minute they get 4 star rating 
-- if they deliver after 20 minute they get 3 star rating.

SELECT rider_id, 
       rating,
	   COUNT(*) AS total_stars
FROM 
(
SELECT rider_id,
       delivery_time_taken,
	   CASE 
	       WHEN delivery_time_taken < 15 THEN '5 star'
           WHEN delivery_time_taken BETWEEN 15 AND 20 THEN '4 star'
       ELSE '3 star'
	   END AS rating	   
FROM
(
SELECT o.order_id,
       o.order_time,
	   d.delivery_time, 
	   EXTRACT(EPOCH FROM (d.delivery_time - o.order_time +
	   CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day'
	   ELSE INTERVAL '0 day' END
	   ))/60 AS delivery_time_taken,
	   d.rider_id
FROM orders AS o
JOIN deliveries AS d
ON o.order_id = d.order_id
WHERE delivery_status = 'Delivered'
) AS t1
) AS t2
GROUP BY 1, 2
ORDER BY 1, 3 DESC;
	

--Q15. Order Frequency by Day:
-- Analyze order frequency per day of the week and identify the peak day for each restaurant.

SELECT * 
FROM 
(
SELECT r.restaurant_name, 
       TO_CHAR(o.order_date, 'Day') As day,
	   COUNT(order_id) AS total_orders,
	   RANK() OVER(PARTITION BY r.restaurant_name ORDER BY COUNT(o.order_id) DESC) AS rank
FROM orders AS o
JOIN restaurants AS r
ON o.restaurant_id = r.restaurant_id
GROUP BY 1, 2
) AS t1
WHERE rank = 1;


--Q16. Customer Lifetime Value (CLV):
-- Calculate the total revenue generated by each customer over all their orders.

SELECT c.customer_id,
       c.customer_name, 
       SUM(o.total_amount) AS CLV
FROM customers AS c
JOIN orders AS o
ON c.customer_id = o.customer_id
GROUP BY 1, 2;


--Q17. Monthly Sales Trends:
-- Identify Sales trends by comparing each month's total sales to the previous month.

SELECT EXTRACT(YEAR FROM order_date) AS year,
       EXTRACT(MONTH FROM order_date) AS month,
       SUM(total_amount) AS total_sale,
	   LAG(SUM(total_amount), 1) OVER(ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)) AS prev_month_sales
FROM orders
GROUP BY 1, 2;


--Q18. Rider Efficiency:
-- evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest averages.x

WITH new_table 
AS
(
SELECT d.rider_id AS rider_id, 
       EXTRACT(EPOCH FROM (d.delivery_time - o.order_time +
	   CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day'
	   ELSE INTERVAL '0 day' END
	   ))/60 AS time_deliver
FROM orders AS o
JOIN deliveries AS d
ON o.order_id = d.order_id
WHERE delivery_status = 'Delivered'
),
rider_time
AS
(
SELECT rider_id, 
       AVG(time_deliver) AS avg_time
FROM new_table
GROUP BY 1
)
SELECT ROUND(MIN(avg_time), 2), 
       ROUND(MAX(avg_time), 2)
FROM rider_time;


--Q19. Order Item Popularity:
-- Track the popularity of specific order items over time and identify seasonal demand spikes.

SELECT order_item,
       seasons,
       COUNT(order_id)
FROM
(
SELECT *,
       EXTRACT(MONTH FROM order_date) AS month,
	   CASE
	       WHEN EXTRACT(MONTH FROM order_date) BETWEEN 4 AND 6 THEN 'Spring'
		   WHEN EXTRACT(MONTH FROM order_date) > 6 AND EXTRACT(MONTH FROM order_date) < 9 THEN 'Summer'
		   ELSE 'Winter'
	   END AS seasons	   
FROM orders
) AS t1
GROUP BY 1, 2
ORDER BY 1, 3 DESC;


--Q20. Rank each city based on the total revenue for last year 2023

SELECT city,
       SUM(o.total_amount) AS total_revenue,
	   EXTRACT(YEAR FROM o.order_date) AS year,
	   DENSE_RANK() OVER(ORDER BY SUM(o.total_amount) DESC) AS city_rank
FROM restaurants AS r
JOIN orders AS o
ON r.restaurant_id = o.restaurant_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2023
GROUP BY 1, 3;

--End of Project

























































































































































































































































































