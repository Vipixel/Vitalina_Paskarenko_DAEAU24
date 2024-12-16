1-----------
SELECT 
    final.country_region,
    final.calendar_year,
    final.channel_desc,
    final.amount_sold,
    final.pct_by_channels,
    final.pct_previous_period,
	TO_CHAR(final.pct_by_channels - final.pct_previous_period, 'FM9990.00') || ' %' AS pct_diff
FROM (
    SELECT sub.country_region,
        sub.calendar_year,
        sub.channel_desc,
        sub.amount_sold,
        sub.pct_by_channels,
        LAG(sub.pct_by_channels) OVER (
            PARTITION BY sub.country_region, sub.channel_desc 
            ORDER BY sub.calendar_year) AS pct_previous_period
    FROM ( 
	SELECT cn.country_region,
            t.calendar_year,
            ch.channel_desc,
            SUM(s.amount_sold) AS amount_sold,
            ROUND(SUM(s.amount_sold) * 100.0 / 
                  SUM(SUM(s.amount_sold)) OVER (PARTITION BY cn.country_region, t.calendar_year ), 2) AS pct_by_channels
        FROM sh.sales s
            JOIN sh.customers c ON s.cust_id = c.cust_id
            JOIN sh.countries cn ON c.country_id = cn.country_id
            JOIN sh.times t ON s.time_id = t.time_id
            JOIN sh.channels ch ON s.channel_id = ch.channel_id
        WHERE cn.country_region IN ('Americas', 'Asia', 'Europe') 
            AND t.calendar_year BETWEEN 1998 AND 2001
            AND ch.channel_desc IN ('Direct Sales', 'Internet', 'Partners')
        GROUP BY cn.country_region, t.calendar_year, ch.channel_desc ) sub) final
---added this to have data for 1999 and 2000, 2001 
WHERE final.calendar_year >= 1999
ORDER BY final.country_region, final.calendar_year, final.channel_desc;
------------------
-------------------

SELECT 
    t.calendar_week_number AS week_number,
    t.time_id,
    t.day_name,
    TO_CHAR(SUM(s.amount_sold),'FM$999,999,999.00') AS sales,
    TO_CHAR(SUM(SUM(s.amount_sold)) OVER (
        PARTITION BY t.calendar_week_number 
        ORDER BY t.time_id),'FM$999,999,999.00') AS cum_sum,
    CASE 
        WHEN t.day_name = 'Monday' THEN 
            TO_CHAR((
                COALESCE(LAG(SUM(s.amount_sold), 2) OVER (ORDER BY t.time_id), 0) + 
                COALESCE(LAG(SUM(s.amount_sold), 1) OVER (ORDER BY t.time_id), 0) +
                SUM(s.amount_sold) + 
                COALESCE(LEAD(SUM(s.amount_sold), 1) OVER (ORDER BY t.time_id), 0)) / 4, 'FM$999,999,999.00')
		WHEN t.day_name = 'Friday' THEN 
            TO_CHAR((
                COALESCE(LAG(SUM(s.amount_sold), 1) OVER (ORDER BY t.time_id), 0) +
                SUM(s.amount_sold) + 
                COALESCE(LEAD(SUM(s.amount_sold), 1) OVER (ORDER BY t.time_id), 0) + 
                COALESCE(LEAD(SUM(s.amount_sold), 2) OVER (ORDER BY t.time_id), 0)) / 4, 'FM$999,999,999.00')
        ELSE 
            TO_CHAR(AVG(SUM(s.amount_sold)) OVER (
                ORDER BY t.time_id
                ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 'FM$999,999,999.00') END AS centered_3_day_avg
FROM sh.sales s
JOIN sh.times t ON s.time_id = t.time_id
WHERE t.calendar_year = 1999
    AND t.calendar_week_number BETWEEN 49 AND 51
GROUP BY t.calendar_week_number, t.time_id, t.day_name
ORDER BY t.calendar_week_number, t.time_id;

-------------------------------------------------
------------------------------------------------
3.1 ---Range

SELECT 
    p.prod_name,
    p.prod_category,
    TO_CHAR(SUM(s.amount_sold), 'FM$999,999,999.00') AS total_sales,
    TO_CHAR(
        SUM(SUM(s.amount_sold)) OVER (
            PARTITION BY p.prod_category
            ORDER BY p.prod_list_price
            RANGE BETWEEN CURRENT ROW AND 100 FOLLOWING ), 'FM$999,999,999.00'
    ) AS cumulative_sales
FROM sh.sales s
JOIN sh.products p ON s.prod_id = p.prod_id
WHERE p.prod_category = 'Electronics'
GROUP BY p.prod_name, p.prod_category, p.prod_list_price
ORDER BY p.prod_list_price;

3.2----Rows

SELECT 
    p.prod_name,
    p.prod_category,
    TO_CHAR(SUM(s.amount_sold), 'FM$999,999,999.00') AS total_sales,
    TO_CHAR(AVG(SUM(s.amount_sold)) OVER (
        PARTITION BY p.prod_category
        ORDER BY p.prod_id
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 'FM$999,999,999.00') AS moving_avg_sales
FROM sh.sales s
JOIN sh.products p ON s.prod_id = p.prod_id
WHERE p.prod_category = 'Hardware'
GROUP BY p.prod_name, p.prod_category, p.prod_id
ORDER BY p.prod_id;

3.3-----Groups

SELECT 
    p.prod_name,
    p.prod_category,
    p.prod_list_price,
    TO_CHAR(SUM(s.amount_sold), 'FM$999,999,999.00')AS total_sales,
    TO_CHAR(AVG(SUM(s.amount_sold)) OVER (
        PARTITION BY p.prod_category
        ORDER BY p.prod_list_price
        GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 'FM$999,999,999.00') AS group_avg_sales
FROM sh.sales s
JOIN sh.products p ON s.prod_id = p.prod_id
WHERE p.prod_category IN ('Electronics', 'Hardware', 'Software/Other')
GROUP BY p.prod_name, p.prod_category, p.prod_list_price
ORDER BY p.prod_list_price;


