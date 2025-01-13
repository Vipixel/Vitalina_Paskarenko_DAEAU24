----------
SELECT 
    final.country_region,
    final.calendar_year,
    final.channel_desc,
    final.amount_sold,
    final.pct_by_channels,
    final.pct_previous_period,
    TO_CHAR(final.pct_by_channels - COALESCE(final.pct_previous_period, 0), 'FM9990.00') || ' %' AS pct_diff
FROM (
    SELECT sub.country_region,
           sub.calendar_year,
           sub.channel_desc,
           sub.amount_sold,
           sub.pct_by_channels,
           AVG(sub.pct_by_channels) OVER (
               PARTITION BY sub.country_region, sub.channel_desc 
               ORDER BY sub.calendar_year
               ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS pct_previous_period
    FROM ( 
        SELECT UPPER(cn.country_region) AS country_region,
               t.calendar_year,
               UPPER(ch.channel_desc) AS channel_desc,
               SUM(s.amount_sold) AS amount_sold,
               ROUND(SUM(s.amount_sold) * 100.0 / 
                     SUM(SUM(s.amount_sold)) OVER (PARTITION BY cn.country_region, t.calendar_year), 2) AS pct_by_channels
        FROM sh.sales s
        JOIN sh.customers c ON s.cust_id = c.cust_id
        JOIN sh.countries cn ON c.country_id = cn.country_id
        JOIN sh.times t ON s.time_id = t.time_id
        JOIN sh.channels ch ON s.channel_id = ch.channel_id
        WHERE UPPER(cn.country_region) IN ('AMERICAS', 'ASIA', 'EUROPE') 
          AND t.calendar_year BETWEEN 1998 AND 2001
          AND UPPER(ch.channel_desc) IN ('DIRECT SALES', 'INTERNET', 'PARTNERS')
        GROUP BY cn.country_region, t.calendar_year, ch.channel_desc 
    ) sub
) final
WHERE final.calendar_year >= 1999
ORDER BY final.country_region, final.calendar_year, final.channel_desc;
------------------
-------------------
SELECT 
    week_data.week_number,
    week_data.time_id,
    week_data.day_name,
    week_data.sales,
    week_data.cum_sum,
    CASE 
        WHEN LOWER(week_data.day_name) IN ('monday', 'sunday') THEN 
            TO_CHAR(AVG(week_data.daily_amount) OVER (
                ORDER BY week_data.time_id
                ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING), 'FM$999,999,999.00')
        WHEN LOWER(week_data.day_name) IN ('friday', 'saturday') THEN 
            TO_CHAR(AVG(week_data.daily_amount) OVER (
                ORDER BY week_data.time_id
                ROWS BETWEEN 1 PRECEDING AND 2 FOLLOWING), 'FM$999,999,999.00')
        ELSE 
            TO_CHAR(AVG(week_data.daily_amount) OVER (
                ORDER BY week_data.time_id
                ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 'FM$999,999,999.00') 
    END AS centered_3_day_avg
FROM (
    SELECT 
        t.calendar_week_number AS week_number,
        t.time_id,
        t.day_name,
        SUM(s.amount_sold) AS daily_amount,
        TO_CHAR(SUM(s.amount_sold),'FM$999,999,999.00') AS sales,
        TO_CHAR(SUM(SUM(s.amount_sold)) OVER (
            PARTITION BY t.calendar_week_number 
            ORDER BY t.time_id),'FM$999,999,999.00') AS cum_sum
    FROM sh.sales s
    JOIN sh.times t ON s.time_id = t.time_id
    WHERE t.calendar_year = 1999
      AND t.calendar_week_number BETWEEN 48 AND 52
    GROUP BY t.calendar_week_number, t.time_id, t.day_name
) week_data
ORDER BY week_data.week_number, week_data.time_id;

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


