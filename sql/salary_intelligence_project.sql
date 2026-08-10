-- ============================================================
-- SALARY INTELLIGENCE PROJECT
-- Purpose:
-- Analyze salaries, job titles, company sizes, work settings,
-- experience levels, and geographic salary differences.
-- ============================================================

-- 1. CREATE AND SELECT THE DATABASE


CREATE DATABASE IF NOT EXISTS salary_intelligence_project;

USE salary_intelligence_project;


-- 2. CREATE THE MAIN TABLE

-- Drop the table first so the script can be rerun without errors.
DROP TABLE IF EXISTS combined_salary_data;

CREATE TABLE combined_salary_data (
    work_year VARCHAR(4),
    job_title VARCHAR(150),
    job_category VARCHAR(100),
    salary_currency VARCHAR(10),
    salary_local DECIMAL(12,2),
    salary_in_usd DECIMAL(12,2),
    employee_residence VARCHAR(100),
    experience_level VARCHAR(15),
    employment_type VARCHAR(15),
    remote_ratio TINYINT,
    company_location VARCHAR(100),
    company_country VARCHAR(100),
    company_size VARCHAR(25),
    data_source VARCHAR(50),
    work_setting_standardized VARCHAR(50)
);


-- 3. IMPORT THE CLEANED CSV FILE


-- LOAD DATA is used instead of the Import Wizard because the
-- Import Wizard does not handle blank numeric values correctly.
--
-- Variables beginning with @ temporarily hold CSV values.
-- NULLIF(value, '') converts blank CSV fields into SQL NULL values.

LOAD DATA LOCAL INFILE
'C:/Users/abaho/source/salary-data-cleaning-analysis/data/cleaned/combined_salary_data.csv'
INTO TABLE combined_salary_data

FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'

-- Skip the CSV header row.
IGNORE 1 LINES

(
    @work_year,
    job_title,
    job_category,
    salary_currency,
    @salary_local,
    @salary_in_usd,
    employee_residence,
    experience_level,
    employment_type,
    @remote_ratio,
    company_location,
    company_country,
    company_size,
    data_source,
    work_setting_standardized
)

SET
    work_year = NULLIF(@work_year, ''),
    salary_local = NULLIF(@salary_local, ''),
    salary_in_usd = NULLIF(@salary_in_usd, ''),
    remote_ratio = NULLIF(@remote_ratio, '');


-- 4. VALIDATE THE DATA IMPORT

-- Confirm the number of imported records.
-- Expected result: 51,939 rows.

SELECT 
    COUNT(*) AS total_rows
FROM
    combined_salary_data;


-- Preview the first 10 records.

SELECT 
    *
FROM
    combined_salary_data
LIMIT 10;


-- Confirm that all three data sources were imported.

SELECT 
    data_source, COUNT(*) AS total_jobs
FROM
    combined_salary_data
GROUP BY data_source
ORDER BY total_jobs DESC;


-- Check the standardized work-setting values.
-- Blank values are expected for the Glassdoor dataset.

SELECT 
    work_setting_standardized, COUNT(*) AS total_jobs
FROM
    combined_salary_data
GROUP BY work_setting_standardized
ORDER BY total_jobs DESC;


-- Check how many records exist for each year.
-- NULL years are expected for the Glassdoor dataset.

SELECT 
    work_year, COUNT(*) AS total_jobs
FROM
    combined_salary_data
GROUP BY work_year
ORDER BY work_year;


-- Check whether company countries were standardized correctly.

SELECT 
    company_country, COUNT(*) AS total_jobs
FROM
    combined_salary_data
GROUP BY company_country
ORDER BY total_jobs DESC;


-- BUSINESS QUESTION 1
-- Which job title earns the highest average salary in
-- Small, Medium, and Large companies?

-- The CTE named ranked_jobs creates a temporary result.
--
-- AVG calculates the average salary for each job title.
-- COUNT counts how many records support that average.
-- HAVING removes job titles with 10 or fewer records.
--
-- ROW_NUMBER ranks job titles inside each company size.
-- PARTITION BY restarts the ranking for each company size.
-- salary_rank = 1 returns the top-paying title from each size.

CREATE VIEW vw_highest_paying_jobs AS

WITH ranked_jobs AS (
    SELECT
        company_size,
        job_title,
        ROUND(AVG(salary_in_usd), 2) AS avg_salary,
        COUNT(*) AS number_of_jobs,

        ROW_NUMBER() OVER (
            PARTITION BY company_size
            ORDER BY AVG(salary_in_usd) DESC
        ) AS salary_rank

    FROM combined_salary_data

    WHERE company_size IS NOT NULL
      AND company_size <> ''
      AND job_title IS NOT NULL
      AND job_title <> ''

    GROUP BY
        company_size,
        job_title

    HAVING COUNT(*) > 10
)

SELECT
    company_size,
    job_title,
    avg_salary,
    number_of_jobs
FROM ranked_jobs
WHERE salary_rank = 1
ORDER BY company_size;


-- OPTIONAL QUERY
-- Highest-paying job title for one company size only
-- Change 'Large' to 'Medium' or 'Small' when needed.

SELECT 
    company_size,
    job_title,
    ROUND(AVG(salary_in_usd), 2) AS avg_salary,
    COUNT(*) AS number_of_jobs
FROM
    combined_salary_data
WHERE
    company_size = 'Large'
GROUP BY company_size , job_title
HAVING COUNT(*) > 10
ORDER BY avg_salary DESC
LIMIT 1;


-- BUSINESS QUESTION 2
-- How does work setting differ by experience level?
-- This counts Remote, Hybrid, and In-person jobs for each
-- experience level.
-- NULL and empty-string values are removed because the
-- Glassdoor dataset does not contain this information.
CREATE VIEW vw_work_setting_by_experience AS
SELECT 
    experience_level,
    work_setting_standardized,
    COUNT(*) AS total_jobs
FROM
    combined_salary_data
WHERE
    experience_level IS NOT NULL
        AND experience_level <> ''
        AND work_setting_standardized IS NOT NULL
        AND work_setting_standardized <> ''
GROUP BY experience_level , work_setting_standardized
ORDER BY experience_level , total_jobs DESC;


-- Check the available experience-level values.

SELECT DISTINCT
    experience_level
FROM
    combined_salary_data
WHERE
    experience_level IS NOT NULL
        AND experience_level <> ''
ORDER BY experience_level;


-- BUSINESS QUESTION 3
-- Does company country affect employee pay?
CREATE VIEW vw_salary_by_country AS
SELECT 
    company_country,
    ROUND(AVG(salary_in_usd), 2) AS avg_salary,
    COUNT(*) AS total_jobs
FROM
    combined_salary_data
WHERE
    company_country IS NOT NULL
        AND company_country <> ''
GROUP BY company_country
HAVING COUNT(*) > 10
ORDER BY avg_salary DESC;


-- OPTIONAL QUESTION
-- Which countries pay Data Scientists the most?

SELECT 
    company_country,
    ROUND(AVG(salary_in_usd), 2) AS avg_salary,
    COUNT(*) AS total_jobs
FROM
    combined_salary_data
WHERE
    job_title LIKE '%Data Scientist%'
        AND company_country IS NOT NULL
        AND company_country <> ''
GROUP BY company_country
HAVING COUNT(*) > 10
ORDER BY avg_salary DESC;


-- BUSINESS QUESTION 4
-- Which experience level earns the highest salary?
-- AVG(salary_in_usd) compares average salaries across levels.
-- COUNT(*) shows how many records support each average.
-- HAVING removes groups with very small sample sizes.
CREATE VIEW vw_salary_by_experience AS
SELECT 
    experience_level,
    ROUND(AVG(salary_in_usd), 2) AS avg_salary,
    COUNT(*) AS total_jobs
FROM
    combined_salary_data
WHERE
    experience_level IS NOT NULL
        AND experience_level <> ''
GROUP BY experience_level
HAVING COUNT(*) > 10
ORDER BY avg_salary DESC;

-- BUSINESS QUESTION 5
-- Which job category has the highest average salary?

CREATE VIEW vw_salary_by_job_category AS
SELECT 
    job_category,
    ROUND(AVG(salary_in_usd), 2) AS avg_salary,
    COUNT(*) AS total_jobs
FROM
    combined_salary_data
WHERE
    job_category IS NOT NULL
        AND job_category <> ''
GROUP BY job_category
HAVING COUNT(*) > 10
ORDER BY avg_salary DESC;

-- BUSINESS QUESTION 6
-- What experience levels are most common in small, medium, and large companies?
-- Groups records by company size and experience level.
-- COUNT(*) measures how common each experience level is.
-- This helps identify the workforce composition of
-- Small, Medium, and Large companies.
CREATE VIEW vw_experience_company_size AS
SELECT 
    company_size, experience_level, COUNT(*) AS total_jobs
FROM
    combined_salary_data
WHERE
    company_size IS NOT NULL
        AND company_size <> ''
        AND experience_level IS NOT NULL
        AND experience_level <> ''
GROUP BY company_size , experience_level
ORDER BY company_size , total_jobs DESC;
    
-- BUSINESS QUESTION 7
-- Does remote work pay more than in-person work?
-- Compares average salary across Remote, Hybrid, and In-person.
-- COUNT(*) is included because the number of records differs
-- significantly between the three work settings.

-- Important:
-- This shows correlation in this dataset, not that work setting
-- itself causes a higher or lower salary.
CREATE VIEW vw_salary_by_work_setting AS
SELECT 
    work_setting_standardized,
    ROUND(AVG(salary_in_usd), 2) AS avg_salary,
    COUNT(*) AS total_jobs
FROM
    combined_salary_data
WHERE
    work_setting_standardized <> ''
GROUP BY work_setting_standardized
ORDER BY avg_salary DESC;

-- BUSINESS QUESTION 8
-- Which countries hire the most data professionals?
-- COUNT(*) measures the number of records for each country.
-- Results are sorted from highest to lowest.
-- LIMIT 10 keeps only the ten countries with the most records,
-- making the result easier to visualize in Power BI.
CREATE VIEW vw_top_countries AS
SELECT 
    company_country, COUNT(*) AS total_jobs
FROM
    combined_salary_data
WHERE
    company_country IS NOT NULL
        AND company_country <> ''
GROUP BY company_country
ORDER BY total_jobs DESC
LIMIT 10;

-- BUSINESS QUESTION 9
-- How have salaries changed over time?
-- Calculates the average salary for each available year.
-- COUNT(*) is included to show the sample size behind each
-- yearly average.

-- Earlier years contain fewer records, so their averages
-- should be interpreted more carefully.
CREATE VIEW vw_salary_over_time AS
SELECT 
    work_year,
    ROUND(AVG(salary_in_usd), 2) AS avg_salary,
    COUNT(*) AS total_jobs
FROM
    combined_salary_data
WHERE
    work_year IS NOT NULL
        AND work_year <> ''
GROUP BY work_year
ORDER BY work_year;

-- BUSINESS QUESTION 10
-- How does salary vary by experience level, company size, and work setting?
-- This is a multi-variable analysis.
-- Each row represents one combination of:
--     experience level + company size + work setting

-- AVG(salary_in_usd) calculates the salary for each combination.
-- COUNT(*) shows the number of records supporting the result.
-- HAVING COUNT(*) > 10 removes combinations with very small
-- sample sizes.

-- This view can be explored with Power BI slicers to compare
-- experience levels, company sizes, and work settings.
CREATE VIEW vw_salary_by_experience_company_size_work_setting AS
SELECT 
    experience_level,
    company_size,
    work_setting_standardized,
    ROUND(AVG(salary_in_usd), 2) AS avg_salary,
    COUNT(*) AS total_jobs
FROM
    combined_salary_data
WHERE
    experience_level IS NOT NULL
        AND experience_level <> ''
        AND work_setting_standardized IS NOT NULL
        AND work_setting_standardized <> ''
        AND company_size IS NOT NULL
        AND company_size <> ''
GROUP BY experience_level , company_size , work_setting_standardized
HAVING COUNT(*) > 10
ORDER BY avg_salary DESC;


-- ============================================================
-- END OF SQL ANALYSIS
-- Data preparation: Python / Pandas
-- Data storage & analysis: MySQL
-- Visualization: Power BI
-- The views created above will be connected to Power BI
-- and used to build the final Salary Intelligence Dashboard.
-- ============================================================







