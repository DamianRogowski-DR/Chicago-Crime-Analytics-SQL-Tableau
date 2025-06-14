-- Check if the 'case number' is unique. If it is not, consider whether it is an accident or a purposeful thing.

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

-- Check the arrest date to see if the case was closed after the arrest.

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

-- Conclusion: 'case_number' is repetitive in some cases. I need to ensure that, when counting cases for analysis, I am counting distinct values.
