------Task 1
SELECT 
    channel_desc AS channel_desc,
    country_region AS country_region,
    TO_CHAR(quantity_sold, '9,999,999.99') AS sales,
    TO_CHAR(quantity_sold * 100 / SUM(quantity_sold) OVER (PARTITION BY channel_desc), '90.99') || '%' AS "SALES %"
FROM (
    SELECT
        ch.channel_desc,
        r.country_region,
        SUM(s.quantity_sold) AS quantity_sold
    FROM sh.sales s
    JOIN sh.channels ch ON s.channel_id = ch.channel_id
    JOIN sh.customers cust ON s.cust_id = cust.cust_id
    JOIN sh.countries r ON cust.country_id = r.country_id
    GROUP BY ch.channel_desc, r.country_region)
ORDER BY country_region ASC, sales DESC;

-----Task 2

SELECT DISTINCT
    prod_subcategory
FROM (
    SELECT
        p.prod_subcategory,
        t.calendar_year,
        SUM(s.amount_sold) AS total_sales,
        LAG(SUM(s.amount_sold)) OVER (PARTITION BY p.prod_subcategory ORDER BY t.calendar_year) AS previous_year_sales
    FROM sh.sales s
    JOIN sh.products p ON s.prod_id = p.prod_id
    JOIN sh.times t ON s.time_id = t.time_id
    WHERE t.calendar_year BETWEEN 1998 AND 2001
    GROUP BY p.prod_subcategory, t.calendar_year) ranked_sales
WHERE calendar_year > 1998
GROUP BY prod_subcategory
HAVING COUNT(CASE WHEN total_sales > previous_year_sales THEN 1 END) = COUNT(*);

-----Task 3
SELECT t.calendar_year AS CALENDAR_YEAR,
    t.calendar_quarter_desc AS CALENDAR_QUARTER_DESC,
    UPPER(p.prod_category) AS PROD_CATEGORY,
    ROUND(SUM(s.amount_sold), 2) AS SALES$,
    CASE 
        WHEN t.calendar_quarter_desc LIKE '%-01' THEN 'N/A'
        ELSE ROUND((SUM(s.amount_sold) - 
                    FIRST_VALUE(SUM(s.amount_sold)) OVER (
                        PARTITION BY t.calendar_year, p.prod_category 
                        ORDER BY t.calendar_quarter_desc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                    )) * 100.0 / FIRST_VALUE(SUM(s.amount_sold)) OVER (
                        PARTITION BY t.calendar_year, p.prod_category 
                        ORDER BY t.calendar_quarter_desc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                    ), 2) || ' %'
    END AS DIFF_PERCENT,
    ROUND(SUM(SUM(s.amount_sold)) OVER 
	(PARTITION BY t.calendar_year
     ORDER BY t.calendar_quarter_desc), 2) AS CUM_SUM$
FROM sh.sales s
    JOIN sh.products p ON s.prod_id = p.prod_id
    JOIN sh.times t ON s.time_id = t.time_id
    JOIN sh.channels ch ON s.channel_id = ch.channel_id
WHERE t.calendar_year IN (1999, 2000) 
    AND LOWER(p.prod_category) IN ('electronics', 'hardware', 'software/other')
    AND LOWER(ch.channel_desc) IN ('partners', 'internet')
GROUP BY t.calendar_year, 
    t.calendar_quarter_desc, 
    p.prod_category
ORDER BY t.calendar_year ASC, 
    t.calendar_quarter_desc ASC, 
    SALES$ DESC;
