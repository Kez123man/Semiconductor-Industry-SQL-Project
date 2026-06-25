--Changes over time trend (Chips prices)
SELECT 
year,
product,
ROUND(SUM(price), 2) as Average_Yrly_Price
FROM chip_prices
WHERE product LIKE 'NAND%'
GROUP BY year, product
ORDER BY year


--Cumulative Analysis (Practice)
SELECT 
year_1, 
t.company_name, -- no "t."
t.country_iso3,  -- no "t."
t.ROUND(sum(revenue_usd_bn),2),
SUM(revenue_usd_bn) OVER(ORDER BY year_1) as Total_revenue
--In the outer query, t.ROUND(sum(revenue_usd_bn),2) is invalid syntax. 
--You can only reference columns from the subquery, not expressions that weren't aliased.
FROM
(
SELECT 
year as year_1,
company_name,
country_iso3,
ROUND(sum(revenue_usd_bn),2),
SUM(revenue_usd_bn) OVER()
FROM chip_companies_financials
GROUP BY company_name, year, country_iso3, segment, revenue_usd_bn
--You're grouping by revenue_usd_bn, which defeats the purpose of SUM(revenue_usd_bn).
) t


--Cumulative Analysis (Real)
SELECT
    company_name,
    year_1,
    country_iso3,
    segment,
    revenue_bn,
    SUM(revenue_bn) OVER ( --Adding OVER() turns the aggregate (SUM) into a window function
        ORDER BY 
        company_name,
        year_1
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS total_revenue,
    AVG(revenue_bn) OVER ( --Adding OVER() turns the aggregate (AVG) into a window function
        ORDER BY 
        company_name,
        year_1
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS moving_avg_price
--Meaning:
--UNBOUNDED PRECEDING = start from the first row
--CURRENT ROW = stop at the current row
FROM (
    SELECT
        company_name,
        year AS year_1,
        segment,
        country_iso3,
        ROUND(SUM(revenue_usd_bn), 2) AS revenue_bn
    FROM chip_companies_financials
    GROUP BY
        company_name,
        year,
        segment,
        country_iso3
) t
ORDER BY company_name, year_1;

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
