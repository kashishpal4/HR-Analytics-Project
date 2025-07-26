-- HR Analytics Case Study - SQL Script
-- This file contains SQL queries used to solve various business and data quality problems.
-- Each query is preceded by a short description of the problem.
-- Results and insights are documented in the final project report and Power BI dashboard.

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
🧹 Section 1: Data Cleaning & Validation
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  
-- Are there any employees with unrealistic age values (below 18 or above 60)?--
SELECT * FROM hr_basic_profile 
WHERE age < 18 OR age > 60;

-- Corrected unrealistic education levels for underage employees--
UPDATE hr_basic_profile 
SET Higher_Education = "12th" 
WHERE Age < 20 AND Higher_Education IN ("Post-Graduation", "PHD");

-- Flagged suspicious education data for review--
UPDATE hr_basic_profile 
SET Higher_Education = "Needs Review" 
WHERE age < 25 AND Higher_Education = "PHD";

-- Checked for null employee IDs in compensation data--
SELECT * FROM hr_compensation_performance WHERE EmpID IS NULL;

-- Checked for duplicate employee IDs in leave data--
SELECT EmpID, COUNT(*) 
FROM hr_leave_recruitment 
GROUP BY EmpID 
HAVING COUNT(*) > 1;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
🔧 Section 2: Feature Engineering
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Created age group bands for better analysis--
ALTER TABLE hr_basic_profile ADD COLUMN age_group VARCHAR(20);
UPDATE hr_basic_profile
SET age_group = CASE 
    WHEN age < 25 THEN "Below 25"
    WHEN age BETWEEN 25 AND 35 THEN "25-35"
    WHEN age BETWEEN 35 AND 50 THEN "35-50"
    ELSE "Above 50"
END;

-- Created experience level bands based on total working years--
ALTER TABLE hr_basic_profile ADD COLUMN Exp_level VARCHAR(20);
UPDATE hr_basic_profile
SET Exp_level = CASE
    WHEN TotalWorkingYears < 2 THEN "Fresher"
    WHEN TotalWorkingYears BETWEEN 2 AND 5 THEN "Junior"
    WHEN TotalWorkingYears BETWEEN 6 AND 10 THEN "Mid-level"
    ELSE "Senior"
END;

-- Added a new column to calculate total off days (leaves + absenteeism)--
ALTER TABLE hr_leave_recruitment ADD COLUMN total_off_days INT;
UPDATE hr_leave_recruitment
SET total_off_days = (Leaves + Absenteeism);

-- Extracted hire year from date of hire--
ALTER TABLE tenure_attrition ADD COLUMN Hire_year INT;
UPDATE tenure_attrition
SET Hire_year = YEAR(Date_of_Hire);

-- Created hire decade bands from hire year--
ALTER TABLE tenure_attrition ADD COLUMN Hire_decade VARCHAR(15);
UPDATE tenure_attrition
SET Hire_decade = CASE 
    WHEN Hire_year BETWEEN 1969 AND 1989 THEN "Before 1990"
    WHEN Hire_year BETWEEN 1990 AND 1999 THEN "1990-1999"
    WHEN Hire_year BETWEEN 2000 AND 2009 THEN "2000-2009"
    WHEN Hire_year BETWEEN 2010 AND 2019 THEN "2010-2019"
    ELSE "Latest hirings"
END;

-- Created tenure band based on years at company--
ALTER TABLE tenure_attrition ADD COLUMN tenure_band VARCHAR(15);
UPDATE tenure_attrition
SET tenure_band = CASE 
    WHEN YearsAtCompany BETWEEN 0 AND 1 THEN "New Joiner"
    WHEN YearsAtCompany BETWEEN 2 AND 5 THEN "Early career"
    WHEN YearsAtCompany BETWEEN 6 AND 12 THEN "Experienced"
    WHEN YearsAtCompany BETWEEN 13 AND 20 THEN "Long-term"
    ELSE "Senior-most"
END;

-- Created promotion status category based on years since last promotion and tenure--
ALTER TABLE tenure_attrition ADD COLUMN Promotion_status VARCHAR(30);
UPDATE tenure_attrition
SET Promotion_status = CASE 
    WHEN YearsAtCompany <= 1 AND YearsSinceLastPromotion = 0 THEN "New hire"
    WHEN YearsAtCompany > 1 AND YearsSinceLastPromotion = 0 THEN "Just promoted"
    WHEN YearsSinceLastPromotion BETWEEN 1 AND 3 THEN "Recently promoted"
    WHEN YearsSinceLastPromotion BETWEEN 4 AND 7 THEN "Promotion delayed"
    ELSE "Needs promotion"
END;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
🔗 Section 3: Data Joining — Creating the Final Dataset
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Created final joined HR dataset by combining all 4 source tables--
CREATE TABLE final_hr_analytics AS 
SELECT 
    p.EmpID, 
    p.Gender, 
    p.MaritalStatus, 
    p.Higher_Education, 
    p.Department, 
    p.JobRole, 
    p.BusinessTravel, 
    p.Job_mode, 
    p.Mode_of_work, 
    p.OverTime, 
    p.age_group, 
    p.Exp_level, 
    
    c.MonthlyIncome,
    c.JobSatisfaction, 
    c.TrainingTimesLastYear,

    l.Source_of_hire, 
    l.Work_accident, 
  
    a.Attrition, 
    a.Status_of_leaving, 
    a.Hire_year, 
    a.Hire_decade, 
    a.YearsAtCompany, 
    a.tenure_band, 
    a.Promotion_status 
FROM 
    hr_basic_profile p 
JOIN 
    hr_compensation_performance c ON p.EmpID = c.EmpID 
JOIN 
    hr_leave_recruitment l ON p.EmpID = l.EmpID 
JOIN 
    tenure_attrition a ON p.EmpID = a.EmpID;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
📊 Exploratory Data Analysis (EDA)
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  
-- What are the distinct years in which employees were hired?--
SELECT DISTINCT Hire_year FROM tenure_attrition;

-- Which year had the highest hirings?--
SELECT 
    Hire_year, 
    COUNT(Hire_year) AS Total_hires 
FROM tenure_attrition 
GROUP BY Hire_year 
ORDER BY Total_hires DESC 
LIMIT 1;

-- How many empplyees reported work accidents?--
SELECT 
    Work_accident, 
    COUNT(EmpID) 
FROM hr_leave_recruitment 
GROUP BY Work_accident;

-- What is the total count and rate of employee attrition?--
SELECT 
    Attrition,
    COUNT(*) AS Attrition_Count,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM tenure_attrition), 1) AS Attrition_Rate
FROM tenure_attrition
GROUP BY Attrition;

--How many employees were hired in each decade?--
SELECT 
    Hire_decade, 
    COUNT(Hire_year) 
FROM tenure_attrition 
GROUP BY Hire_decade;

-- What is the average tenure for each tenure band?--
SELECT 
    tenure_band, 
    ROUND(AVG(YearsAtCompany)) 
FROM tenure_attrition 
GROUP BY tenure_band;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
📌 Key Business Insights & Final Analysis Queries
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  
--  Which department has the highest number of active employees?--
SELECT 
    Department, 
    COUNT(Attrition) AS Active_employees
FROM final_hr_analytics
WHERE Attrition = 'No'
GROUP BY Department
ORDER BY Active_employees DESC;

-- Which age groups have the highest number of attrition?--
SELECT 
    age_group, 
    COUNT(Attrition)
FROM final_hr_analytics
WHERE Attrition = 'Yes'
GROUP BY age_group
ORDER BY COUNT(Attrition);

-- Which departments have the highest number of attrition?--
SELECT 
    Department,
    ROUND(COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 1) AS AttritionRate
FROM final_hr_analytics
GROUP BY Department
ORDER BY AttritionRate DESC;

-- How is attrition distributed by overtime status?--
SELECT 
    OverTime, 
    COUNT(Attrition)
FROM final_hr_analytics
WHERE Attrition = 'Yes'
GROUP BY OverTime;

--  What are the different reasons for which employees left the company?--
SELECT 
    Status_of_leaving, 
    COUNT(Attrition) 
FROM tenure_attrition 
WHERE Attrition = "Yes" 
GROUP BY Status_of_leaving;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 🔍 Trial Queries: (Kept here to show deep exploration during EDA)
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Added a column to calculate termination year for those who left--
ALTER TABLE final_hr_analytics ADD COLUMN Termination_year VARCHAR(20);
UPDATE final_hr_analytics
SET Termination_year = CASE
    WHEN Attrition = "Yes" THEN Hire_year + YearsAtCompany
    ELSE "Active"
END;

-- Dropped termination year column as not needed after review--
ALTER TABLE final_hr_analytics DROP COLUMN Termination_year;

-- Checked min, max, and average salary--
SELECT MIN(MonthlyIncome), MAX(MonthlyIncome), ROUND(AVG(MonthlyIncome)) 
FROM hr_compensation_performance;

-- Checked job satisfaction with avg salary hike--
SELECT 
    JobSatisfaction, 
    AVG(PercentSalaryHike) 
FROM hr_compensation_performance 
GROUP BY JobSatisfaction;

-- Total employee count by tenure--
SELECT 
    YearsAtCompany, 
    COUNT(YearsAtCompany) 
FROM tenure_attrition 
GROUP BY YearsAtCompany;

-- What is the distribution of hires by different sources? --
SELECT 
    Source_of_Hire, 
    COUNT(EmpID) 
FROM hr_leave_recruitment 
GROUP BY Source_of_Hire;

-- What is the average absenteeism across different job modes? --
SELECT 
    Job_mode, 
    AVG(Absenteeism) 
FROM hr_leave_recruitment 
GROUP BY Job_mode;

-- What is the distribution of employees based on their mode of work? --
SELECT Mode_of_work, COUNT(Mode_of_work) 
FROM hr_basic_profile 
GROUP BY Mode_of_work;

-- Checked if stock option levels affect job satisfaction --
SELECT 
    StockOptionLevel, 
    TRUNCATE(AVG(JobSatisfaction), 1), 
    ROUND(AVG(MonthlyIncome)) 
FROM hr_compensation_performance 
GROUP BY StockOptionLevel;

-- Checked if average income affects job satisfaction--
SELECT 
    JobSatisfaction, 
    ROUND(AVG(MonthlyIncome)) 
FROM hr_compensation_performance 
GROUP BY JobSatisfaction;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
