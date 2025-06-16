WITH all_months_by_type_community AS (
    -- Generate all possible months for each community_area and primary_type
    SELECT
        ca.community_area,
        pt.primary_type,
        DATE_TRUNC('month', gs.month_start) AS crime_month
	-- Used DISTINCT to build a complete "matrix" of all possible crime types across all community areas, without generating redundant intermediate rows.
    FROM (SELECT DISTINCT community_area FROM crimes) AS ca
    CROSS JOIN (SELECT DISTINCT primary_type FROM crimes) AS pt 
    CROSS JOIN GENERATE_SERIES(
        (SELECT MIN(DATE_TRUNC('month', date)) FROM crimes),
        (SELECT MAX(DATE_TRUNC('month', date)) FROM crimes),
        '1 month'::interval
    ) AS gs(month_start)
),
monthly_crime_counts_with_zeros AS (
	-- Count the number of crimes committed in a month 
    SELECT
        amm.community_area,
        amm.primary_type,
        amm.crime_month,
		-- Used COALESCE to ensure that any month-type-area combination that had no crimes reported will show a month_crime_count of 0 instead of NULL 
        COALESCE(COUNT(DISTINCT c.case_number), 0) AS month_crime_count
    FROM
        all_months_by_type_community amm
    LEFT JOIN
        crimes c ON amm.community_area = c.community_area
                 AND amm.primary_type = c.primary_type
                 AND amm.crime_month = DATE_TRUNC('month', c.date)
    GROUP BY
        amm.community_area,
        amm.primary_type,
        amm.crime_month
),
crime_counts_minus_one AS (
    SELECT
        community_area,
        primary_type,
        crime_month,
        month_crime_count,
		-- Used window function that allows to access data from a previous row
        LAG(month_crime_count, 1) OVER (PARTITION BY community_area, primary_type ORDER BY crime_month) AS previous_month_crime_count
    FROM
        monthly_crime_counts_with_zeros
)
-- Month-over-month percentage change in crime counts
SELECT
    community_area,
    primary_type,
    crime_month,
    month_crime_count,
    previous_month_crime_count,
	-- Handling potential issues like NULL values or division by zero.
    CASE
        WHEN previous_month_crime_count IS NULL THEN NULL
        WHEN previous_month_crime_count = 0 THEN NULL
        ELSE round(((month_crime_count - previous_month_crime_count)::NUMERIC / previous_month_crime_count) * 100,2)
    END AS percentage_change
FROM
    crime_counts_minus_one
ORDER BY
    community_area,
    primary_type,
    crime_month ASC;