USE pizza_db;

-- DATA INTEGRITY & AUDIT VERIFICATION
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS total_orders,
    MIN(order_date) AS earliest_date,
    MAX(order_date) AS latest_date,
    ROUND(SUM(total_price), 2) AS total_revenue
FROM pizza_sales;

-- EXECUTIVE KPI BENCHMARKS (FOR POWER BI TOP CARDS)

-- Total Revenue generated across the entire year.
SELECT ROUND(SUM(total_price), 2) AS Total_Revenue 
FROM pizza_sales;

-- Average Order Value (AOV) — average revenue earned per distinct transaction.
SELECT ROUND(SUM(total_price) / COUNT(DISTINCT order_id), 2) AS Avg_Order_Value 
FROM pizza_sales;

-- Total volume of pizza units produced and sold by the kitchen.
SELECT SUM(quantity) AS Total_Pizzas_Sold 
FROM pizza_sales;

-- Total distinct orders placed by customers.
SELECT COUNT(DISTINCT order_id) AS Total_Orders 
FROM pizza_sales;

-- Average basket size (units per ticket) to gauge meal combo uptake.
SELECT ROUND(SUM(quantity) / COUNT(DISTINCT order_id), 2) AS Avg_Pizzas_Per_Order 
FROM pizza_sales;

-- TEMPORAL & OPERATIONAL TRENDS (FOR TIME-SERIES CHARTS)

-- Daily trend for total orders.
SELECT 
    DAYNAME(order_date) AS Order_Day,
    COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales
GROUP BY DAYNAME(order_date)
ORDER BY Total_Orders DESC;

-- Monthly trend for total orders.
SELECT 
    MONTHNAME(order_date) AS Month_Name,
    COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales
GROUP BY MONTHNAME(order_date), MONTH(order_date)
ORDER BY MONTH(order_date) ASC;

-- PRODUCT MIX & CATEGORY SHARE (FOR DONUT & FUNNEL CHARTS)

-- Percentage of sales by pizza category.
SELECT 
    pizza_category,
    ROUND(SUM(total_price), 2) AS Total_Revenue,
    ROUND(SUM(total_price) * 100 / (SELECT SUM(total_price) FROM pizza_sales), 2) AS Sales_Percentage
FROM pizza_sales
GROUP BY pizza_category
ORDER BY Sales_Percentage DESC;

-- Percentage of sales by pizza category filtered by specific month (e.g., January).
SELECT 
    pizza_category,
    ROUND(SUM(total_price), 2) AS Total_Revenue,
    ROUND(SUM(total_price) * 100 / (SELECT SUM(total_price) FROM pizza_sales WHERE MONTH(order_date) = 1), 2) AS Sales_Percentage
FROM pizza_sales
WHERE MONTH(order_date) = 1
GROUP BY pizza_category
ORDER BY Sales_Percentage DESC;

-- Percentage of sales by pizza size.
SELECT 
    pizza_size,
    ROUND(SUM(total_price), 2) AS Total_Revenue,
    ROUND(SUM(total_price) * 100 / (SELECT SUM(total_price) FROM pizza_sales), 2) AS Sales_Percentage
FROM pizza_sales
GROUP BY pizza_size
ORDER BY Sales_Percentage DESC;

-- Percentage of sales by pizza size filtered by specific quarter (e.g., Q1).
SELECT 
    pizza_size,
    ROUND(SUM(total_price), 2) AS Total_Revenue,
    ROUND(SUM(total_price) * 100 / (SELECT SUM(total_price) FROM pizza_sales WHERE QUARTER(order_date) = 1), 2) AS Sales_Percentage
FROM pizza_sales
WHERE QUARTER(order_date) = 1
GROUP BY pizza_size
ORDER BY Sales_Percentage DESC;

-- Total pizzas sold by pizza category.
SELECT 
    pizza_category,
    SUM(quantity) AS Total_Quantity_Sold
FROM pizza_sales
GROUP BY pizza_category
ORDER BY Total_Quantity_Sold DESC;

-- BEST & WORST SELLERS (TOP 5 & BOTTOM 5)

-- Top 5 pizzas by revenue.
SELECT 
    pizza_name, 
    ROUND(SUM(total_price), 2) AS Total_Revenue
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_Revenue DESC
LIMIT 5;

-- Bottom 5 pizzas by revenue.
SELECT 
    pizza_name, 
    ROUND(SUM(total_price), 2) AS Total_Revenue
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_Revenue ASC
LIMIT 5;

-- Top 5 pizzas by quantity sold.
SELECT 
    pizza_name, 
    SUM(quantity) AS Total_Pizza_Sold
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_Pizza_Sold DESC
LIMIT 5;

-- Bottom 5 pizzas by quantity sold.
SELECT 
    pizza_name, 
    SUM(quantity) AS Total_Pizza_Sold
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_Pizza_Sold ASC
LIMIT 5;

-- Top 5 pizzas by total orders.
SELECT 
    pizza_name, 
    COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_Orders DESC
LIMIT 5;

-- Bottom 5 pizzas by total orders.
SELECT 
    pizza_name, 
    COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_Orders ASC
LIMIT 5;

-- STRATEGIC & ADVANCED ANALYTICAL QUERIES

-- Operational shift capacity and rush-hour profiling.
SELECT 
    CASE 
        WHEN HOUR(order_time) BETWEEN 11 AND 13 THEN 'Lunch Rush (11 AM - 1:59 PM)'
        WHEN HOUR(order_time) BETWEEN 14 AND 16 THEN 'Afternoon Slump (2 PM - 4:59 PM)'
        WHEN HOUR(order_time) BETWEEN 17 AND 20 THEN 'Dinner Peak (5 PM - 8:59 PM)'
        WHEN HOUR(order_time) >= 21 THEN 'Late Night (9 PM+)'
        ELSE 'Opening (Before 11 AM)'
    END AS Operational_Window,
    COUNT(DISTINCT order_id) AS Total_Orders,
    SUM(quantity) AS Total_Pizzas_Made,
    ROUND(SUM(total_price), 2) AS Total_Revenue,
    ROUND(SUM(total_price) / COUNT(DISTINCT order_id), 2) AS Window_AOV
FROM pizza_sales
GROUP BY Operational_Window
ORDER BY Total_Revenue DESC;

-- Pareto 80/20 cumulative revenue analysis using window functions.
WITH PizzaRevenue AS (
    SELECT 
        pizza_name,
        ROUND(SUM(total_price), 2) AS Revenue
    FROM pizza_sales
    GROUP BY pizza_name
),
ParetoCalculations AS (
    SELECT 
        pizza_name,
        Revenue,
        ROUND(SUM(Revenue) OVER(ORDER BY Revenue DESC), 2) AS Cumulative_Revenue,
        ROUND(SUM(Revenue) OVER(), 2) AS Grand_Total_Revenue
    FROM PizzaRevenue
)
SELECT 
    pizza_name,
    Revenue,
    Cumulative_Revenue,
    ROUND((Cumulative_Revenue / Grand_Total_Revenue) * 100, 2) AS Cumulative_Pct,
    CASE 
        WHEN (Cumulative_Revenue / Grand_Total_Revenue) * 100 <= 80.00 THEN 'Top 80% Driver'
        ELSE 'Long Tail (Bottom 20%)'
    END AS Pareto_Classification
FROM ParetoCalculations
ORDER BY Revenue DESC;

-- Market basket co-occurrence: identifying pizza pairs frequently ordered together.
SELECT 
    a.pizza_name AS Pizza_A,
    b.pizza_name AS Pizza_B,
    COUNT(DISTINCT a.order_id) AS Times_Ordered_Together
FROM pizza_sales a
JOIN pizza_sales b 
    ON a.order_id = b.order_id 
    AND a.pizza_name < b.pizza_name
GROUP BY a.pizza_name, b.pizza_name
ORDER BY Times_Ordered_Together DESC
LIMIT 10;