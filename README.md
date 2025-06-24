# chicago_crime_analytics
### A tool to identify crime trends in the "City of the Big Shoulders".

Tool used: PostgreSQL, Tableau

[Chicago Crime Analytics - Tableau](https://public.tableau.com/app/profile/damian.rogowski/viz/ChicagoCrimeAnalytics_17501438440230/Dashboard1)

## Business case evaluation

* Business Problem: The Chicago Chief of Police is having trouble tracking and monitoring crime trends in his city. Although the data is well gathered and stored, asking data specialists for a report on crime rates for a specific community or area is ineffective and time-consuming. They need a data analytics solution that will gather useful information in a clear, uncomplicated way, making it possible to conduct ad hoc analysis and uncover valuable patterns and trends.
* My solution: To help Chief and his colleagues gather valuable insights that are important for city safety, I plan to use my SQL and data visualisation skills. SQL will enable me to build a precise query that tailors the data to showcase valuable trends and numbers. The data visualisation tool I have chosen, Tableau, will help me present this data in a clear and approachable way to help officers instantly spot patterns in the dataset. The dashboard will be designed to support filtering the data by the three main aspects: community area of the city, type of crime and year. The questions that are important for this task are as follows:
  * Have there been any significant increases or decreases in specific crime types compared to the previous month? If so, by what percentage?
  * Are there any discernible patterns in the seasonality of crime? For example, do certain types of crime tend to spike during particular months or seasons? What is the 'crime season' during a year?
  * Which districts or communities have the lowest reported crime rates? Which community is the safest? 

## Data Preparation
I gathered all the data used in this task from the [Chicago Data Portal](https://data.cityofchicago.org). This analysis is based on data set [Crimes - 2001 to Present](https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-Present/ijzp-q8t2/about_data), I've applied a filter on the site to download data ranging from January 1, 2020, at 12:00:00 AM to December 31, 2024, at 11:45:00 PM. The visualization of Chicago communities utilized mapping data from [chicago Community areas](https://data.cityofchicago.org/Facilities-Geographic-Boundaries/chicago-Community-areas/m39i-3ntz). 

## Data Processing 
Prior to preparing the data for dashboard input, I conducted a data validation to confirm its integrity and completeness. A key aspect of this validation was checking for duplicate 'case_number' entries. 
```
WITH case_number_count AS

(
SELECT 
case_number, 
count(*) AS count_of_cases
FROM public.crimes
GROUP BY case_number
)

SELECT
cnc.case_number, 
cnc.count_of_cases
FROM case_number_count AS cnc
WHERE count_of_cases > 1
GROUP BY 
cnc.case_number,
cnc.count_of_cases
ORDER BY 
cnc.count_of_cases DESC;

```
Result:

<img src="https://github.com/DamianRogowski-DR/chicago_crime_analytics/blob/main/process_querry_output/case_number_unique_check.png" width="200" height="280">

As duplicates were found, the analysis was subsequently performed using the DISTINCT count of 'case_number' values.

To investigate the origin of these duplicates, I cross-referenced the data with an [Arrest](https://data.cityofchicago.org/Public-Safety/Arrests/dpt3-jri9/about_data) dataset, specifically looking at whether cases conclude upon an arrest. 
```
SELECT
    c.case_number,
    a.arrest_date
FROM
    public.crimes AS c
INNER JOIN
    public.arrests AS a ON c.case_number = a.case_number
WHERE
    c.case_number IN 
	(
        SELECT
            case_number
        FROM
            public.crimes
        GROUP BY
            case_number
        HAVING
            COUNT(*) > 2
    );

```
Result:

<img src="https://github.com/DamianRogowski-DR/chicago_crime_analytics/blob/main/process_querry_output/case_number_arrest_date.png" width="200" height="280">

The presence of duplicate case numbers appears to stem from scenarios such as repeated crime reporting.

## Data Analysis
At thi stage, I used SQL to pre-calculate the input for my visualisation. To keep the results accountable, I have done three main things:

1. Following my latest discovery, I made sure that I was counting distinct values.

2. I generated months within the query to ensure that the percentage change from one month to the next would not skip any months in which a specific crime type did not appear.

3. I have made sure that each community will be analysed separately. This will make filtering by community areas possible and improve the overall accuracy of the analysis.

By incorporating several advanced features for robust data manipulation, I managed to create a very complex query based on common table expressions, scalar queries and joins. Functions such as DATE_TRUNC, COALESCE and LAG were also used. I made sure that the values to be calculated would not cause any errors and successfully handled potential issues such as NULL values or division by zero. The whole query with my comments below:

```
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
    
```
To facilitate data visualization, the query output was exported to CSV format using the COPY command. 

## Data Visualization

The visualization component of this project comprises three key elements designed to provide a foundational understanding of crime patterns: two time-series charts illustrating the monthly sum of reported crimes and the average monthly percentage change in crime, respectively, and a geospatial map of Chicago depicting crime rates across various communities.

Despite a streamlined visual design, the underlying data analysis reveals significant trends and critical insights into crime patterns. Analysis of data from 2020 to 2024 indicates that overall crime incidence is highest between May and October, with three distinct peaks observed annually in March, May, and July. Furthermore, the Austin community area consistently records the highest volume of reported crimes, accumulating over 60,000 incidents within the four-year period.

The interactive filters for Community Area and Crime Type enable users to perform granular analysis, allowing for the identification of crime trends within specific communities or to display overall crime rates for a particular Crime Type.

You can view the final visualization [here](https://public.tableau.com/app/profile/damian.rogowski/viz/ChicagoCrimeAnalytics_17501438440230/Dashboard1)





