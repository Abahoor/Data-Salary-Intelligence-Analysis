import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

pd.set_option("display.max_columns", None)
print("Libraries imported successfully!")

#Get the data
df_1=pd.read_csv("data/raw/DataAnalyst_set1_raw.csv")
df_2=pd.read_csv("data/raw/jobs_in_data_set2_raw.csv")
df_3=pd.read_csv("data/raw/global_ai_ml_data_salaries_set3_raw.csv")

#Start cleaning the first dataset
df_1.drop(columns=["Unnamed: 0"], inplace=True)
df_1.drop(columns=["Job Description"],inplace=True)

#changing the values of Easy Apply to 0's and 1's so its easyer to use in mysql
df_1["Easy Apply"]=df_1["Easy Apply"].replace({"True": 1 , "-1": 0})

#cleaning Salary Estimate and convirting it to three colums
df_1["Salary Estimate"] = df_1["Salary Estimate"].str.replace("(Glassdoor est.)","")
df_1["Salary Estimate"]=df_1["Salary Estimate"].str.replace("$","")
df_1["Salary Estimate"] =df_1["Salary Estimate"] .str.replace("K","")

#creat salary_min and salary_max out of Salary Estimate
df_1[["salary_min","salary_max"]] = df_1["Salary Estimate"].str.split("-",expand=True) 

#Deleting the row with the missing value so I could change the data type of both salary_min and salary_max
bad_row = df_1[df_1["Salary Estimate"] == "-1"].index
df_1=df_1.drop(bad_row)

#changing the data type
df_1["salary_min"]=df_1["salary_min"].astype(int)
df_1["salary_max"]=df_1["salary_max"].astype(int)

#Creat salary_avg
df_1["salary_avg"]=(df_1["salary_min"]+df_1["salary_max"])/2
print("------------------------------------------")
#print(df_1.columns)
# change the place of the colums
col1=df_1.pop("salary_min")
col2=df_1.pop("salary_max")
col3=df_1.pop("salary_avg")
df_1.insert(2,"salary_min",col1)
df_1.insert(3,"salary_max",col2)
df_1.insert(4,"salary_avg",col3)
#print(df_1.columns)

df_1.to_csv("data/cleaned/data_analyst_set1_cleaned.csv",index=False)

#Data-set-2

#Converted company_size codes (S/M/L) to Small/Medium/Large.
df_2["company_size"] = df_2["company_size"].replace("S","Small")
df_2["company_size"] = df_2["company_size"].replace("M","Medium")
df_2["company_size"] = df_2["company_size"].replace("L","Large")

df_2.to_csv("data/cleaned/jobs_in_data_set2_cleaned.csv",index=False)

#Data-set-3

#Expanded experience level abbreviations.
df_3["experience_level"] = df_3["experience_level"].replace("SE","Senior level")
df_3["experience_level"] = df_3["experience_level"].replace("MI","Mid level")
df_3["experience_level"] = df_3["experience_level"].replace("EN","Entry level")
df_3["experience_level"] = df_3["experience_level"].replace("EX","Executive level")

#Expanded employment type abbreviations.
df_3["employment_type"] = df_3["employment_type"].replace("FT","Full time")
df_3["employment_type"] = df_3["employment_type"].replace("PT","Part-time")
df_3["employment_type"] = df_3["employment_type"].replace("CT","Contract")
df_3["employment_type"] = df_3["employment_type"].replace("FL","Freelance")

#Expanded company size abbreviations.
df_3["company_size"] = df_3["company_size"].replace("L","Large")
df_3["company_size"] = df_3["company_size"].replace("M","Medium")
df_3["company_size"] = df_3["company_size"].replace("S","Small")

df_3.to_csv("data/cleaned/global_ai_ml_data_salaries_set3_cleaned.csv",index=False)

#preparation to combine the three data sets

set1 = df_1.copy()
set2 = df_2.copy()
set3 = df_3.copy()
#standardiz compant size
set1["company_size_standardized"] = set1["Size"].replace({
    "1 to 50 employees": "Small",
    "51 to 200 employees": "Medium",
    "201 to 500 employees": "Large",
    "501 to 1000 employees": "Large",
    "1001 to 5000 employees": "Large",
    "5001 to 10000 employees": "Large",
    "10000+ employees": "Large",
    "-1": "Unknown"
})
# Creat set1 from dataset1 and standardiz the column name
set1_standardized = pd.DataFrame({
    "work_year" : pd.NA,
    "job_title" : set1["Job Title"],
    "job_category" : pd.NA,
    "salary_currency" : "USA",
    "salary" : set1["salary_avg"]*1000,
    "salary_in_usd" : set1["salary_avg"]*1000,
    "employee_residence" : pd.NA,
    "experience_level" : pd.NA,
    "employment_type" : pd.NA,
    "remote_ratio" : pd.NA,
    "company_location" : set1["Location"],
    "company_size" : set1["company_size_standardized"],
    "data_source" : "Glassdoor Data Analyst Jobs"
})

set2["remote_ratio"] = set2["work_setting"].map({
    "In-person": 0,
    "Hybrid": 50,
    "Remote": 100
})
# Same as set1
#set 2 was created from dataset2
set2_standardized = pd.DataFrame({
    "work_year" : set2["work_year"],
    "job_title" : set2["job_title"],
    "job_category" : set2["job_category"],
    "salary_currency" : set2["salary_currency"],
    "salary" : set2["salary"],
    "salary_in_usd" : set2["salary_in_usd"],
    "employee_residence" : set2["employee_residence"],
    "experience_level" : set2["experience_level"],
    "employment_type" : set2["employment_type"],
    "work_setting" : set2["work_setting"],
    "company_location" : set2["company_location"],
    "company_size" : set2["company_size"],
    "data_source": "Jobs in Data"
})
#standardiz experience_level so it the same as every dataset
set3["experience_level"] = set3["experience_level"].replace({
    "Entry level": "Entry-level",
    "Mid level": "Mid-level",
    "Senior level": "Senior",
    "Executive level": "Executive"
})
#standardiz employment_type so it the same as every dataset
set3["employment_type"] = set3["employment_type"].replace({
    "Full time": "Full-time",
    "Part-time": "Part-time",
    "Contract": "Contract",
    "Freelance": "Freelance"
})
#set 3 was created from dataset3
set3_standardized = pd.DataFrame({
    "work_year": set3["work_year"],
    "job_title": set3["job_title"],
    "job_category": pd.NA,
    "salary_currency": set3["salary_currency"],
    "salary": set3["salary"],
    "salary_in_usd": set3["salary_in_usd"],
    "employee_residence": set3["employee_residence"],
    "experience_level": set3["experience_level"],
    "employment_type": set3["employment_type"],
    "remote_ratio": set3["remote_ratio"],
    "company_location": set3["company_location"],
    "company_size": set3["company_size"],
    "data_source": "Global AI/ML Salaries"
})
#Combin all sets to one value
combined_salary_data = pd.concat([
    set1_standardized,
    set2_standardized,
    set3_standardized

], ignore_index=True)

#combined_salary_data["job_title"].combine_first(combined_salary_data["job_title"])

combined_salary_data.rename(
    columns={"salary": "salary_local"},
    inplace=True
)

combined_salary_data["work_setting_standardized"] = combined_salary_data["remote_ratio"].replace({
    0: "In-person",
    50: "Hybrid",
    100: "Remote"
})

combined_salary_data["work_setting_standardized"]= (
    combined_salary_data["work_setting_standardized"].
    combine_first(combined_salary_data["work_setting"]))

combined_salary_data.drop(columns=["work_setting"], inplace=True)

combined_salary_data = combined_salary_data.astype(object).where(
    combined_salary_data.notna(),
    None
)

# Keep the original location column
combined_salary_data["company_country"] = (combined_salary_data["company_location"].copy())

# Convert country codes into full country names
country_mapping = {
    "US": "United States",
    "CA": "Canada",
    "GB": "United Kingdom",
    "DE": "Germany",
    "ES": "Spain",
    "AU": "Australia",
    "IN": "India",
    "FR": "France",
    "NL": "Netherlands",
    "BR": "Brazil",
    "LT": "Lithuania",
    "ZA": "South Africa",
    "PT": "Portugal",
    "IE": "Ireland",
    "MX": "Mexico",
    "EG": "Egypt",
    "PL": "Poland",
    "AR": "Argentina",
    "IT": "Italy",
    "NZ": "New Zealand",
    "CO": "Colombia",
    "TR": "Turkey",
    "PH": "Philippines",
    "GR": "Greece",
    "AT": "Austria",
    "LV": "Latvia",
    "CH": "Switzerland",
    "UA": "Ukraine",
    "EE": "Estonia",
    "FI": "Finland",
    "NG": "Nigeria",
    "IL": "Israel",
    "JP": "Japan",
    "MT": "Malta",
    "RU": "Russia",
    "SE": "Sweden",
    "BE": "Belgium",
    "RO": "Romania",
    "DK": "Denmark",
    "SI": "Slovenia",
    "CL": "Chile",
    "AE": "United Arab Emirates",
    "SG": "Singapore",
    "KR": "South Korea",
    "AS": "American Samoa",
    "LU": "Luxembourg",
    "KE": "Kenya",
    "HU": "Hungary",
    "VN": "Vietnam",
    "PR": "Puerto Rico",
    "AM": "Armenia",
    "SA": "Saudi Arabia",
    "CZ": "Czech Republic",
    "GH": "Ghana",
    "TH": "Thailand",
    "HR": "Croatia",
    "CY": "Cyprus",
    "VE": "Venezuela",
    "SK": "Slovakia",
    "DZ": "Algeria",
    "RS": "Serbia",
    "BA": "Bosnia and Herzegovina",
    "LB": "Lebanon",
    "NO": "Norway",
    "CF": "Central African Republic",
    "PK": "Pakistan",
    "ID": "Indonesia",
    "BG": "Bulgaria",
    "OM": "Oman",
    "GI": "Gibraltar",
    "MU": "Mauritius",
    "QA": "Qatar",
    "AD": "Andorra",
    "EC": "Ecuador",
    "HK": "Hong Kong",
    "IR": "Iran",
    "BS": "Bahamas",
    "MY": "Malaysia",
    "HN": "Honduras",
    "IQ": "Iraq",
    "CN": "China",
    "MD": "Moldova"
}

combined_salary_data["company_country"] = (
    combined_salary_data["company_country"].replace(country_mapping)
)

us_state_pattern = (
    r",\s*(?:AL|AK|AZ|AR|CA|CO|CT|DE|FL|GA|HI|ID|IL|IN|IA|KS|KY|LA|"
    r"ME|MD|MA|MI|MN|MS|MO|MT|NE|NV|NH|NJ|NM|NY|NC|ND|OH|OK|OR|"
    r"PA|RI|SC|SD|TN|TX|UT|VT|VA|WA|WV|WI|WY|DC)$"
)

us_city_mask = combined_salary_data["company_country"].str.contains(
    us_state_pattern,
    regex=True,
    na=False
)

combined_salary_data.loc[us_city_mask, "company_country"] = "United States"

##col1=df_1.pop("salary_min")

cl=combined_salary_data.pop("company_country")
combined_salary_data.insert(11,"company_country",cl)


print(combined_salary_data.dtypes)

print(combined_salary_data.shape)
print("--------------")
print(combined_salary_data.columns)
print("--------------")
print(combined_salary_data["data_source"].value_counts())

combined_salary_data.to_csv("data/cleaned/combined_salary_data.csv",index=False)