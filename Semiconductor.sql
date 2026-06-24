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
