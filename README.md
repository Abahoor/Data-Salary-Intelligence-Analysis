# Data Salary Intelligence Analysis

## Project Overview

This project analyzes salary and employment patterns across data-related careers using three separate datasets with different structures and levels of data quality.

The main goal was to build a complete data-analysis workflow: clean and standardize messy data in **Python/Pandas**, combine the sources into one analytical dataset, load the result into **MySQL**, answer business questions with SQL, create reusable SQL views, and connect those views to **Power BI** for reporting and visualization.

**Workflow**

`Raw Data → Python/Pandas Cleaning → Standardized Combined Dataset → MySQL Analysis → SQL Views → Power BI Dashboard → Conclusions`

The final combined dataset contains **51,939 records**.

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| Python | Data cleaning and preparation |
| Pandas | Data manipulation, standardization, and dataset combination |
| NumPy | Supporting data-processing work |
| MySQL | Data storage, validation, and analysis |
| SQL | Aggregation, filtering, ranking, and creation of reporting views |
| Power BI | Dashboard creation and data visualization |
| VS Code | Python development |
| Git / GitHub | Version control and project presentation |

---

## Data Sources

The project combines three datasets:

1. **Glassdoor Data Analyst Jobs** — [View on Kaggle](https://www.kaggle.com/datasets/andrewmvd/data-analyst-jobs)
2. **Jobs in Data** — [View on Kaggle](https://www.kaggle.com/datasets/hummaamqaasim/jobs-in-data)
3. **Global AI/ML Salaries** — [View on Kaggle](https://www.kaggle.com/datasets/msjahid/global-ai-ml-and-data-science-salaries)

Because the datasets were created independently, they did not share the same schema, naming conventions, or level of completeness. A major part of the project was therefore focused on cleaning and standardization before any analysis was performed.

---

## Data Cleaning & Preparation

### Dataset 1 — Glassdoor Data Analyst Jobs

This dataset required the most cleaning.

Main steps included:

- Removed unnecessary columns such as `Unnamed: 0` and `Job Description`.
- Converted `Easy Apply` values into numeric values.
- Cleaned the `Salary Estimate` field by removing text such as:
  - `$`
  - `K`
  - `(Glassdoor est.)`
- Split the salary range into:
  - `salary_min`
  - `salary_max`
- Converted salary fields to numeric values.
- Created `salary_avg`.
- Converted salary values from thousands into full salary amounts.
- Standardized company sizes into:
  - Small
  - Medium
  - Large
  - Unknown

Example:

```text
$80K-$120K (Glassdoor est.)
```

became approximately:

```text
salary_min = 80000
salary_max = 120000
salary_avg = 100000
```

---

### Dataset 2 — Jobs in Data

This dataset was more structured, but several categorical fields still needed to be standardized.

Company-size codes were converted:

```text
S → Small
M → Medium
L → Large
```

Work-setting values were also mapped to remote ratios:

```text
In-person → 0
Hybrid    → 50
Remote    → 100
```

---

### Dataset 3 — Global AI/ML Salaries

Abbreviated categorical values were expanded and standardized.

Experience levels:

```text
EN → Entry-level
MI → Mid-level
SE → Senior
EX → Executive
```

Employment types:

```text
FT → Full-time
PT → Part-time
CT → Contract
FL → Freelance
```

Company-size codes were also converted into Small, Medium, and Large.

---

## Standardizing and Combining the Three Datasets

Before combining the datasets, a common structure was created so that equivalent information would appear under the same column names.

The final analytical structure includes:

```text
work_year
job_title
job_category
salary_currency
salary_local
salary_in_usd
employee_residence
experience_level
employment_type
remote_ratio
company_location
company_country
company_size
data_source
work_setting_standardized
```

The standardized datasets were then combined with Pandas using `pd.concat()`.

A `data_source` column was retained so each record could still be traced back to its original source.

---

## Work-Setting Standardization

Two of the datasets represented work setting differently.

One used numeric remote-ratio values:

```text
0   → In-person
50  → Hybrid
100 → Remote
```

while another already contained text values.

A new field called `work_setting_standardized` was created so both formats could be combined into one consistent field.

---

## Geographic Standardization

Location cleaning was one of the more important preparation steps because the original data contained a mixture of:

- Country codes
- Full country names
- U.S. city/state locations
- International locations

A new `company_country` column was created while preserving the original `company_location` field.

Country codes were converted to full country names, for example:

```text
US → United States
GB → United Kingdom
CA → Canada
DE → Germany
FR → France
AU → Australia
```

U.S. locations such as:

```text
New York, NY
Chicago, IL
San Francisco, CA
Austin, TX
```

were standardized to:

```text
United States
```

This prevented equivalent locations from being treated as separate countries during analysis.

---

# MySQL Workflow

After cleaning and combining the datasets, the final CSV was imported into a MySQL database called:

```sql
salary_intelligence_project
```

The main table is:

```sql
combined_salary_data
```

`LOAD DATA LOCAL INFILE` was used instead of the MySQL import wizard so blank numeric values could be converted safely to SQL `NULL` values.

The SQL script also includes validation queries to:

- Confirm the expected **51,939 rows** were imported.
- Preview the data.
- Check record counts by source.
- Check work-setting values.
- Check record counts by year.
- Validate standardized country values.

---

# Business Questions

The analysis was designed around ten business questions.

### 1. Which job title earns the highest average salary in Small, Medium, and Large companies?

A CTE and `ROW_NUMBER()` window function were used to rank job titles within each company size rather than ranking all job titles together.

A minimum sample-size condition was also used to reduce the influence of titles represented by very few records.

### 2. How does work setting differ by experience level?

Remote, Hybrid, and In-person records were counted for each experience level to compare how work arrangement changes across Entry-level, Mid-level, Senior, and Executive positions.

### 3. Does company country affect employee pay?

Average salary was compared across countries while also tracking the number of observations supporting each country's average.

Countries with very small samples were excluded from the salary comparison.

> This analysis shows salary differences associated with country in this dataset. It does not prove that country itself causes the salary difference.

### 4. Which experience level earns the highest salary?

Average salary was calculated for each experience level and compared using the number of supporting records.

### 5. Which job category has the highest average salary?

Average salaries were compared across job categories such as Machine Learning & AI, Data Science and Research, Data Engineering, and Data Analysis.

### 6. What experience levels are most common in Small, Medium, and Large companies?

Records were grouped by both company size and experience level to examine workforce composition.

### 7. Does remote work pay more than in-person work?

Average salaries were compared across In-person, Remote, and Hybrid work settings.

Because the groups contain very different numbers of observations, record counts were included when interpreting the result.

### 8. Which countries hire the most data professionals?

Countries were ranked by record count, with the SQL view limited to the top countries for easier reporting.

### 9. How have salaries changed over time?

Average salary was calculated for each available year from 2020 through 2024, together with the number of observations in each year.

### 10. How does salary vary by experience level, company size, and work setting?

This multi-variable analysis compares average salary across combinations of:

- Experience level
- Company size
- Work setting

Combinations with 10 or fewer records were excluded to reduce the influence of extremely small samples.

---

# SQL Techniques Used

The SQL portion of the project includes:

- `SELECT`
- `WHERE`
- `GROUP BY`
- `HAVING`
- `ORDER BY`
- `COUNT()`
- `AVG()`
- `ROUND()`
- `LIMIT`
- `LIKE`
- `DISTINCT`
- Common Table Expressions (`WITH`)
- `ROW_NUMBER()`
- Window functions
- `PARTITION BY`
- SQL views
- `LOAD DATA LOCAL INFILE`
- `NULLIF()`

Ten SQL views were created for Power BI:

```text
vw_highest_paying_jobs
vw_work_setting_by_experience
vw_salary_by_country
vw_salary_by_experience
vw_salary_by_job_category
vw_experience_company_size
vw_salary_by_work_setting
vw_top_countries
vw_salary_over_time
vw_salary_by_experience_company_size_work_setting
```

---

# Power BI Dashboard

The Power BI report contains four pages:

1. **Salary Overview**
2. **Career & Company Insights**
3. **Location & Work**
4. **Conclusion & Key Findings**

The report uses a consistent dark theme with cyan, purple, orange, and blue accents.

---

## 1. Salary Overview

![Salary Overview](images/Salary%20Overview.png)

This page provides a high-level view of compensation across the dataset.

It includes:

- Overall average salary
- Total job records
- Highest-paid experience level
- Highest-paid job category
- Average salary trend over time
- Average salary by experience level
- Average salary by job category

### Main Findings

- Overall average salary is approximately **$155K**.
- **Executive-level** positions have the highest average salary at approximately **$198K**.
- **Machine Learning & AI** is the highest-paying analyzed job category at approximately **$179K**.
- Average salaries in the available records generally increase after 2021.

---

## 2. Career & Company Insights

![Career & Company Insights](images/CAREER%20%26%20COMPANY%20INSIGHTS.png)

This page examines how company size, experience level, and work setting relate to salary and workforce composition.

### Highest-Paying Job by Company Size

Among job titles meeting the SQL sample-size requirement:

- **Medium companies:** Engineering Manager — approximately **$273K**
- **Large companies:** Applied Scientist — approximately **$187K**
- **Small companies:** Machine Learning Scientist — approximately **$150K**

### Experience-Level Distribution

Senior-level roles represent the largest share of records in both Medium and Large companies, while Small companies show a more balanced distribution across Entry-level, Mid-level, and Senior positions.

### Work-Setting Distribution

In-person positions make up the majority of observations across every experience level.

Remote work represents a meaningful share of the data, while Hybrid records are comparatively rare.

---

## 3. Location & Work

![Location & Work](images/Location%20%26%20Work.png)

This page focuses on geographic salary differences and work-setting patterns.

It includes:

- Average Salary by Country
- Average Salary by Work Setting
- Top Countries by Job Listings

### Main Findings

Among countries retained in the salary comparison:

- United States: approximately **$160K**
- Canada: approximately **$143K**
- Australia: approximately **$130K**

The country comparison should be interpreted cautiously because the dataset is heavily concentrated in the United States.

For work setting:

- **In-person:** approximately **$163K**
- **Remote:** approximately **$149K**
- **Hybrid:** approximately **$85K**

The Hybrid result is based on a much smaller sample and should therefore not be interpreted as evidence that Hybrid jobs generally pay less.

---

## 4. Conclusion & Key Findings

![Conclusion & Key Findings](images/Conclusion%20%26%20Key%20Findings.png)

The final page summarizes the main findings while also documenting the limitations that affect interpretation.

---

# Key Findings

- Average salary is approximately **$155K** across the analyzed salary records.
- **Machine Learning & AI** has the highest average salary among the analyzed job categories.
- **Executive-level roles** earn the highest average salary, followed by Senior, Mid-level, and Entry-level roles.
- Salaries show a **general upward trend from 2020 to 2024** in the available data, with the strongest increases occurring after 2021.
- **In-person positions** have the highest observed average salary in this dataset, followed by Remote positions, while Hybrid positions have the lowest observed average.
- **Senior-level roles** are the most common experience level in the dataset.
- Medium-sized companies account for substantially more observations than Small or Large companies.

---

# Data Limitations

Understanding the limitations of the data is an important part of interpreting the dashboard.

## U.S.-Focused Dataset

The dataset is heavily concentrated in the United States.

The United States accounts for the overwhelming majority of country-level job records, so the results should not be treated as a balanced representation of the global data-job market.

---

## Unequal Sample Sizes Across Years

The number of observations changes substantially by year:

| Year | Records |
|---|---:|
| 2020 | 146 |
| 2021 | 415 |
| 2022 | 3,292 |
| 2023 | 15,975 |
| 2024 | 29,859 |

Because 2020 and 2021 contain much smaller samples, the salary-over-time result should **not** be interpreted as definitive evidence of market-wide salary growth.

It only describes the salary pattern present in the records available in this combined dataset.

---

## Hybrid Jobs Are Underrepresented

The work-setting analysis contains approximately:

| Work Setting | Records |
|---|---:|
| In-person | 36,829 |
| Remote | 12,407 |
| Hybrid | 451 |

Because Hybrid positions have a much smaller sample, their salary average should be interpreted cautiously.

---

## Unequal Country Samples

Some countries have far more records than others.

Country salary comparisons were therefore filtered to avoid emphasizing averages calculated from only a few observations.

---

## Multiple Data Sources

The final dataset combines information from three independent sources.

Each source may differ in:

- Data-collection methods
- Job classifications
- Geographic coverage
- Time coverage
- Available fields

These differences may influence the results after the datasets are combined.

---

# Overall Takeaway

Data salaries vary substantially based on **career level, specialization, company characteristics, location, and work setting**.

Within this dataset, higher experience levels and specialized fields such as **Machine Learning & AI** are associated with higher average salaries. Company size and work arrangement also reveal meaningful differences in workforce composition and compensation.

However, the analysis also demonstrates why **sample size and dataset composition must be considered before drawing broader conclusions**. The data is heavily U.S.-focused, the earliest years contain relatively few records, Hybrid positions are underrepresented, and the three source datasets do not contain identical information.

Overall, the project highlights meaningful patterns in data-career salaries while also showing the importance of evaluating the quality, coverage, and limitations of the underlying data before interpreting those patterns as representative of the wider job market.

---

# Project Structure

A suggested repository structure is:

```text
salary-data-cleaning-analysis/
│
├── dashboard/
│   └── Data Career & Salary Intelligence Dashboard.pbix
│
├── data/
│   ├── cleaned/
│   │   ├── combined_salary_data.csv
│   │   ├── data_analyst_set1_cleaned.csv
│   │   ├── global_ai_ml_data_salaries_set3_cleaned.csv
│   │   └── jobs_in_data_set2_cleaned.csv
│   │
│   └── raw/
│       ├── DataAnalyst_set1_raw.csv
│       ├── global_ai_ml_data_salaries_set3_raw.csv
│       └── jobs_in_data_set2_raw.csv
│
├── images/
│   ├── CAREER & COMPANY INSIGHTS .png
│   ├── Conclusion & Key Findings.png
│   ├── Location & Work.png
│   └── Salary Overview.png
│
├── notebooks/
│   ├── Data_cleaning.py
│   └── notebook.ipynb
│
├── sql/
│   └── salary_intelligence_project.sql
│
└── README.md
```

---

# How to Run the Project

### 1. Clean and combine the datasets

Run the Python cleaning script from the project root:

```bash
python scripts/data_cleaning.py
```

The final combined file will be written to:

```text
data/cleaned/combined_salary_data.csv
```

### 2. Create and populate the MySQL database

Run:

```text
sql/salary_analysis.sql
```

The SQL script:

- Creates the database and table.
- Imports the cleaned CSV.
- Validates the import.
- Creates the analytical views used by Power BI.

> `LOAD DATA LOCAL INFILE` must be enabled in the MySQL client and server for the provided import method.

### 3. Open the Power BI report

Open:

```text
dashboard/salary_intelligence_dashboard.pbix
```

If the report is opened on another machine, the MySQL connection may need to be updated to point to that machine's MySQL server.

---

# Skills Demonstrated

- Python
- Pandas
- Data Cleaning
- Data Transformation
- Data Standardization
- Dataset Integration
- Missing-Value Handling
- Geographic Standardization
- MySQL
- SQL Aggregation
- SQL Filtering
- CTEs
- Window Functions
- `ROW_NUMBER()`
- SQL Views
- Power BI
- Dashboard Design
- Data Visualization
- Exploratory Data Analysis
- Business Question Development
- Data Quality Assessment
- Interpretation of Sample-Size Limitations

---

## Final Note

This project was built as an end-to-end data-analysis portfolio project, with an emphasis on not only producing results but also understanding how cleaning decisions, missing information, unequal sample sizes, and source differences affect the conclusions that can reasonably be drawn from the data.
