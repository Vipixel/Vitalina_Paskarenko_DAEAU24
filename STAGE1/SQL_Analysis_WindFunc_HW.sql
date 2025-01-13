-----Task 1
SELECT 
    channel_desc,
    cust_last_name,
    cust_first_name,
    sales$ AS amount_sold,
    sales_percentage,
    row_number
FROM (
    SELECT
        ch.channel_desc,
        cust.cust_id,
        cust.cust_last_name,
        cust.cust_first_name,
        TO_CHAR(SUM(s.amount_sold), '9,999,999.99') AS sales$,
        TO_CHAR(SUM(s.amount_sold) * 100 / SUM(SUM(s.amount_sold)) OVER (PARTITION BY ch.channel_desc), '9D99999 %') AS sales_percentage,
        ROW_NUMBER() OVER (PARTITION BY channel_desc ORDER BY SUM(s.amount_sold) DESC) AS row_number
    FROM sh.sales s
    JOIN sh.customers cust ON s.cust_id = cust.cust_id
    JOIN sh.channels ch ON s.channel_id = ch.channel_id
    GROUP BY 
        ch.channel_desc, 
        cust.cust_id,
        cust.cust_last_name, 
        cust.cust_first_name
) ranked_customers
WHERE row_number <= 5
ORDER BY channel_desc, row_number;

----Task 2

SELECT 
    LOWER(p.prod_name) AS product_name,
    ROUND(SUM(s.amount_sold) FILTER (WHERE t.calendar_quarter_number = 1), 2) AS q1,
    ROUND(SUM(s.amount_sold) FILTER (WHERE t.calendar_quarter_number = 2), 2) AS q2,
    ROUND(SUM(s.amount_sold) FILTER (WHERE t.calendar_quarter_number = 3), 2) AS q3,
    ROUND(SUM(s.amount_sold) FILTER (WHERE t.calendar_quarter_number = 4), 2) AS q4,
    ROUND(SUM(s.amount_sold), 2) AS year_sum
FROM sh.sales s
JOIN sh.products p ON p.prod_id = s.prod_id
JOIN sh.customers cust ON cust.cust_id = s.cust_id
JOIN sh.times t ON t.time_id = s.time_id
JOIN sh.channels ch ON ch.channel_id = s.channel_id
JOIN sh.countries cn ON cn.country_id = cust.country_id
WHERE 
    LOWER(p.prod_category) = 'photo'
    AND UPPER(cn.country_region) = 'ASIA'
    AND t.calendar_year = 2000
GROUP BY LOWER(p.prod_name)
ORDER BY year_sum DESC;

----Task 3 

SELECT 
    channel_desc,
    cust_id,
    cust_last_name,
    cust_first_name,
    total_sales,
    row_number
FROM (
    SELECT 
        ch.channel_desc,
        cust.cust_id,
        cust.cust_last_name,
        cust.cust_first_name,
        ROUND(SUM(s.amount_sold), 2) AS total_sales, 
        ROW_NUMBER() OVER (PARTITION BY t.calendar_year ORDER BY SUM(s.amount_sold) DESC) AS row_number
    FROM sh.sales s
    JOIN sh.customers cust ON s.cust_id = cust.cust_id
    JOIN sh.channels ch ON s.channel_id = ch.channel_id
    JOIN sh.times t ON s.time_id = t.time_id
    WHERE t.calendar_year IN (1998, 1999, 2001)
    GROUP BY 
        ch.channel_desc,
        cust.cust_id,
        cust.cust_last_name,
        cust.cust_first_name,
        t.calendar_year
) ranked_customers
WHERE row_number <= 300 
ORDER BY row_number;

---Task 4

SELECT 
    TO_CHAR(s.time_id, 'YYYY-MM') AS calendar_month_desc,
    LOWER(p.prod_category) AS product_category,
    SUM(s.amount_sold) FILTER (WHERE UPPER(c.country_region) = 'AMERICAS') AS americas_sales,
    SUM(s.amount_sold) FILTER (WHERE UPPER(c.country_region) = 'EUROPE') AS europe_sales
FROM sh.sales s
JOIN sh.products p ON s.prod_id = p.prod_id
JOIN sh.customers cust ON s.cust_id = cust.cust_id
JOIN sh.countries c ON cust.country_id = c.country_id
WHERE UPPER(c.country_region) IN ('EUROPE', 'AMERICAS')
    AND s.time_id BETWEEN '2000-01-01' AND '2000-03-31'
GROUP BY TO_CHAR(s.time_id, 'YYYY-MM'), LOWER(p.prod_category)
ORDER BY TO_CHAR(s.time_id, 'YYYY-MM'), LOWER(p.prod_category);
