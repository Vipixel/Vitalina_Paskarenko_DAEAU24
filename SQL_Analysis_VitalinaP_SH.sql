SELECT * FROM sh.channels LIMIT 10;
SELECT * FROM sh.costs LIMIT 10;
SELECT * FROM sh.customers LIMIT 10;
SELECT * FROM sh.countries LIMIT 10;
SELECT * FROM sh.products LIMIT 10;
SELECT * FROM sh.promotions LIMIT 10;
SELECT * FROM sh.sales LIMIT 10;
SELECT * FROM sh.times LIMIT 10;
SELECT * FROM sh.supplementary_demographics LIMIT 10;
SELECT * FROM sh.profits LIMIT 1000;

-- countries - stores geographical info like country, region, city
-- customers - stores personal data about customers name, gender, home adress
-- channels - shows sales channels
-- times -shows day details, like day of the week
-- products - shows product and price  what help analyze sales perfomance
-- promotions - store data about promotions, including their channels, to analyze their impact and see which promotional channel is more effective
-- costs - tracks transactional data like sales and promotions.
-- sales - focuses on details about sales channels
-- supplementary_demographics - additional details about customers, with helpful insights to better understand who the customer is allowing for more targeted and engaging promotions
-- profits (it not a schema table but view)- shows which product, channel, and promotion combination led to a sale and at what price.

---3

SELECT p.prod_category, SUM(pr.amount_sold) AS sales_amount
FROM sh.profits pr
JOIN sh.products p ON p.prod_id = pr.prod_id
WHERE time_id < '1998-02-02'
GROUP BY p.prod_category
ORDER BY sales_amount DESC;

-- Calculate the average sales quantity by region for a particular product

SELECT p.prod_name, AVG(s.quantity_sold) AS avg_quantity, cn.country_region
FROM sh.sales s
JOIN sh.products p ON p.prod_id = s.prod_id
JOIN sh.customers c ON c.cust_id = s.cust_id
JOIN sh.countries cn ON cn.country_id = c.country_id
WHERE p.prod_id = '16'
GROUP BY p.prod_name,cn.country_region
ORDER BY avg_quantity DESC;

-- Find the top five customers with the highest total sales amount

SELECT c.cust_first_name, c.cust_last_name, SUM(quantity_sold*amount_sold) as sales_amount 
FROM sh.customers c
JOIN sh.sales s ON s.cust_id = c.cust_id
GROUP BY c.cust_first_name, c.cust_last_name
ORDER BY sales_amount DESC
LIMIT 5;

