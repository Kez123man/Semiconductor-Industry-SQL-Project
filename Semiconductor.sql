--Changes over time trend (Chips prices)
SELECT 
year_date,
product,
ROUND(SUM(price), 2) as Average_Yrly_Price
FROM chip_prices
WHERE product LIKE 'NAND%'
GROUP BY year_date, product
ORDER BY year_date


--Cumulative Analysis (Practice)
SELECT 
year_date, 
t.company_name, -- no "t."
t.country_iso3,  -- no "t."
t.ROUND(sum(revenue_usd_bn),2),
SUM(revenue_usd_bn) OVER(ORDER BY year_date) as Total_revenue
--In the outer query, t.ROUND(sum(revenue_usd_bn),2) is invalid syntax. 
--You can only reference columns from the subquery, not expressions that weren't aliased.
FROM
(
SELECT 
year_date,
company_name,
country_iso3,
ROUND(sum(revenue_usd_bn),2),
SUM(revenue_usd_bn) OVER()
FROM chip_companies_financials
GROUP BY company_name, year_date, country_iso3, segment, revenue_usd_bn
--You're grouping by revenue_usd_bn, which defeats the purpose of SUM(revenue_usd_bn).
) t


--Cumulative Analysis (Real)
SELECT
    company_name,
    year_date,
    country_iso3,
    segment,
    revenue_bn,
    SUM(revenue_bn) OVER ( --Adding OVER() turns the aggregate (SUM) into a window function
        ORDER BY 
        company_name,
        year_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS total_revenue,
    AVG(revenue_bn) OVER ( --Adding OVER() turns the aggregate (AVG) into a window function
        ORDER BY 
        company_name,
        year_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS moving_avg_price
--Meaning:
--UNBOUNDED PRECEDING = start from the first row
--CURRENT ROW = stop at the current row
FROM (
    SELECT
        company_name,
        year_date,
        segment,
        country_iso3,
        ROUND(SUM(revenue_usd_bn), 2) AS revenue_bn
    FROM chip_companies_financials
    GROUP BY
        company_name,
        year_date,
        segment,
        country_iso3
) t
ORDER BY company_name, year_date;

--Performance Analysis
WITH Units_Ship AS (
SELECT
year_date,
chip_name,
vendor,
SUM(estimated_shipments_units) as Total_units_shipped
FROM
ai_chip_market
GROUP BY
year_date,
vendor,
chip_name
) 

SELECT 
year_date,
chip_name,
vendor,
Total_units_shipped,
AVG(Total_units_shipped) OVER (PARTITION BY chip_name) AS avg_unit_ship,
--year over year analysis
CASE WHEN Total_units_shipped - AVG(Total_units_shipped) OVER (PARTITION BY chip_name) > 0 THEN 'Above Average'
	 WHEN Total_units_shipped - AVG(Total_units_shipped) OVER (PARTITION BY chip_name)  < 0 THEN 'Below Average'
	 ELSE 'AVG'
END avg_chng,
LAG(Total_units_shipped) OVER(PARTITION BY chip_name ORDER BY year_date) AS previous_year_shipped, 
Total_units_shipped - LAG(Total_units_shipped) OVER(PARTITION BY chip_name ORDER BY year_date) AS diff_units_shipped
FROM 
Units_Ship
year_date

-- Part-to-Whole Analysis 

-- Which company contributes the most to overall R&D Spending?

WITH rd_spend AS 
(
SELECT
company_name,
SUM(rd_spend_usd_bn) AS total_RD_comp
FROM
chip_companies_financials
WHERE rd_spend_usd_bn > 0
GROUP BY 
company_name
--rd_spend_usd_bn
)

SELECT
company_name,
ROUND(total_RD_comp,2) AS total_RD_comp_BN,
ROUND(SUM(total_RD_comp) OVER (),2) AS all_rd_sum_BN,
CONCAT(ROUND((total_RD_comp/SUM(total_RD_comp) OVER ()) * 100, 2), '%') AS all_rd_sum_per
FROM
rd_spend
GROUP BY 
company_name,
total_RD_comp
ORDER BY total_RD_comp_BN DESC
;


-- Data Segmentation

-- 

WITH node_segment AS
(
SELECT 
company,
country_iso3,
process_node_nm,
CASE WHEN process_node_nm <= 5 THEN '0-5 nodes'
	WHEN process_node_nm BETWEEN 6 AND 10 THEN '6-10 nodes'
	WHEN process_node_nm BETWEEN 11 AND 20 THEN '11-20 nodes'
	ELSE 'Over 20 nodes'
END node_nm_range
FROM 
fab_capacity
GROUP BY
company,
country_iso3,
process_node_nm)

SELECT
COUNT(node_nm_range) AS total_nm_nodes,
node_nm_range
FROM
node_segment
GROUP BY
node_nm_range
ORDER BY total_nm_nodes;
