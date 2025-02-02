create schema healthcare;

use healthcare;

SHOW VARIABLES LIKE 'local_infile';

SET GLOBAL local_infile = 1;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/healthcare_dataset.csv'
INTO TABLE healthcare_data
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(Name, Age, Gender, Blood_Type, Medical_Condition, Admission_date, Doctor, Hospital, Insurance_Provider,
  Billing_Amount, Room_Number, Admission_Type, Discharge_Date, Medication, Test_Results);
  
  
  -- Diactive Safe update mode
SET SQL_SAFE_UPDATES = 0;

-- Change the data to date 
UPDATE healthcare_data
SET Admission_date = STR_TO_DATE(Admission_date, '%m/%d/%Y');

-- Change the column datatype text to Date
alter table healthcare_data
modify column Admission_date DATE;

-- Active Safe update mode
SET SQL_SAFE_UPDATES = 1;


-- Change the data to date 
UPDATE healthcare_data
SET Discharge_Date = STR_TO_DATE(Discharge_Date, '%m/%d/%Y');

-- Change the column datatype text to Date
alter table healthcare_data
modify column Discharge_Date DATE;


DELIMITER //

CREATE PROCEDURE Dimensiontable()
BEGIN
    -- Drop the fact table if it exists
    DROP TABLE IF EXISTS Dim_Patient;
	CREATE TABLE Dim_Patient (
		Patient_ID INT PRIMARY KEY AUTO_INCREMENT,
		Name VARCHAR(100) NOT NULL,
		Age INT NOT NULL,
		Gender VARCHAR(10) NOT NULL,
		Blood_Type VARCHAR(3) NOT NULL,
		Medical_Condition VARCHAR(100) NOT NULL
	);

	INSERT INTO Dim_Patient (Name, Age, Gender, Blood_Type, Medical_Condition)
	SELECT DISTINCT Name, Age, Gender, Blood_Type, Medical_Condition 
	FROM healthcare_data;


	DROP TABLE IF EXISTS Dim_Doctor;
	-- dimension table
	CREATE TABLE Dim_Doctor (
		Doctor_ID INT PRIMARY KEY AUTO_INCREMENT,
		Doctor_Name VARCHAR(100) NOT NULL,
		Hospital VARCHAR(100) NOT NULL
	);
	INSERT INTO Dim_Doctor (Doctor_Name, Hospital)
	SELECT DISTINCT Doctor, Hospital 
	FROM healthcare_data;


	DROP TABLE IF EXISTS Dim_Hospital;
	-- dimension table
	CREATE TABLE Dim_Hospital (
		Hospital_ID INT PRIMARY KEY AUTO_INCREMENT,
		Hospital_Name VARCHAR(100) NOT NULL,
		Insurance_Provider VARCHAR(100) NOT NULL
	);

	INSERT INTO Dim_Hospital (Hospital_Name, Insurance_Provider)
	SELECT DISTINCT Hospital, Insurance_Provider 
	FROM healthcare_data;


	DROP TABLE IF EXISTS Dim_Admission;
	-- dimension table
	CREATE TABLE Dim_Admission (
		Admission_ID INT PRIMARY KEY AUTO_INCREMENT,
		Admission_Type VARCHAR(50) NOT NULL,
		Room_Number INT NOT NULL
	);
	INSERT INTO Dim_Admission (Admission_Type, Room_Number)
	SELECT DISTINCT Admission_Type, Room_Number 
	FROM healthcare_data;


	DROP TABLE IF EXISTS Dim_Medication;
	-- dimension table
	CREATE TABLE Dim_Medication (
		Medication_ID INT PRIMARY KEY AUTO_INCREMENT,
		Medication_Name VARCHAR(100) NOT NULL
	);
	INSERT INTO Dim_Medication (Medication_Name)
	SELECT DISTINCT Medication 
	FROM healthcare_data;


	DROP TABLE IF EXISTS Dim_Test_Results;
	-- dimension table
	CREATE TABLE Dim_Test_Results (
		Test_Result_ID INT PRIMARY KEY AUTO_INCREMENT,
		Test_Result VARCHAR(100) NOT NULL
	);
	INSERT INTO Dim_Test_Results (Test_Result)
	SELECT DISTINCT Test_Results 
	FROM healthcare_data;
END //

DELIMITER ;

call Dimensiontable();



		

-- Now creating a fact table
DELIMITER //

CREATE PROCEDURE Facttable()
BEGIN
    -- Drop the fact table if it exists
    DROP TABLE IF EXISTS Fact_Admissions;
	-- create fact table
	CREATE TABLE Fact_Admissions (
		Fact_ID INT PRIMARY KEY AUTO_INCREMENT,
		Patient_ID INT,
		Doctor_ID INT,
		Hospital_ID INT,
		Admission_ID INT,
		Medication_ID INT,
		Test_Result_ID INT,
		Admission_Date DATE NOT NULL,
		Discharge_Date DATE NOT NULL,
		Billing_Amount DECIMAL(10,2) NOT NULL
	);

	-- Insert data into the fact table
	INSERT INTO Fact_Admissions (
		 Patient_ID, Doctor_ID, Hospital_ID, Admission_ID, Medication_ID, Test_Result_ID, Admission_Date, Discharge_Date, Billing_Amount
	)

	-- Use CTEs to deduplicate and prepare data for insertion
	WITH DeduplicatedData AS (
		SELECT 
			*,
			ROW_NUMBER() OVER (
				PARTITION BY 
					 Name, Age, Gender, Blood_Type, Medical_Condition, Admission_date, Doctor, Hospital, 
					 Insurance_Provider, Billing_Amount, Room_Number,
					 Admission_Type, Discharge_Date, Medication, Test_Results
				ORDER BY 
					Admission_date
			) AS rn
		FROM healthcare_data 
	),
	FilteredData AS (
		SELECT *
		FROM DeduplicatedData 
		WHERE rn = 1 
	)
	SELECT 
		p.Patient_ID,
		d.Doctor_ID, 
		h.Hospital_ID, 
		a.Admission_ID, 
		m.Medication_ID, 
		t.Test_Result_ID, 
		fd.Admission_Date, 
		fd.Discharge_Date, 
		fd.Billing_Amount
	FROM FilteredData AS fd
	JOIN Dim_Patient p ON fd.Name = p.Name AND fd.Age = p.Age AND fd.Gender = p.Gender AND fd.Blood_Type = p.Blood_Type AND fd.Medical_Condition = p.Medical_Condition
	JOIN Dim_Doctor d ON fd.Doctor = d.Doctor_Name AND fd.Hospital = d.Hospital
	JOIN Dim_Hospital h ON fd.Hospital = h.Hospital_Name AND fd.Insurance_Provider = h.Insurance_Provider
	JOIN Dim_Admission a ON fd.Admission_Type = a.Admission_Type AND fd.Room_Number = a.Room_Number
	JOIN Dim_Medication m ON fd.Medication = m.Medication_Name
	JOIN Dim_Test_Results t ON fd.Test_Results = t.Test_Result;

END //

DELIMITER ;

call Facttable;


select * from fact_admissions;

-- cheek my fact table is okay or not
SELECT Patient_ID, 
       Doctor_ID, 
       Hospital_ID, 
       Admission_ID, 
       Medication_ID, 
       Test_Result_ID, 
       Admission_Date, 
       Discharge_Date, 
       Billing_Amount ,
       COUNT(*) AS duplicate_count
FROM Fact_Admissions
GROUP BY Patient_ID, Doctor_ID, Hospital_ID, Admission_ID, Medication_ID, Test_Result_ID, Admission_Date, Discharge_Date, Billing_Amount
HAVING COUNT(*) > 1;



select * from dim_patient;

-- Questions
-- Q1. What is the top 3 highest billing amount for each doctor?

with DoctorBilling as (
select Doctor_ID,
       sum(billing_amount) as Total_billing
from fact_admissions
group by Doctor_ID
),
RankedDoctor as (
select Doctor_ID,
	Total_billing,
    Rank() Over(order by Total_billing desc) as Ranked
from DoctorBilling
)
select Doctor_ID,Total_billing
from RankedDoctor
where Ranked <= 3;


-- Q2. Find the patients who had the longest and shortest stays in the hospital for each hospital.

with StayDurations as (
select Patient_ID,
       Hospital_ID,
       Datediff(Discharge_date, Admission_date) as Stay_Duration
from fact_Admissions
),
RankedStay as (
select Patient_ID,
       Hospital_ID,
       Stay_Duration,
       Rank() OVER (Partition by Hospital_ID order by Stay_Duration desc) as Max_Rank,
       Rank() OVER (Partition by Hospital_ID order by Stay_Duration asc) as Min_Rank
from StayDurations
)
select Patient_ID,
       Hospital_ID,
       Stay_Duration
from RankedStay
where Max_Rank = 1 OR Min_Rank = 1;


-- Q3. which doctors have seen patients with all medical conditions?

with DoctorPatientConditions as (
	select d.Doctor_ID,
		   dp.Medical_Condition
	from dim_doctor d
	join fact_Admissions fa on d.Doctor_ID = fa.Doctor_ID
	join Dim_Patient as dp on fa.Patient_ID = dp.Patient_ID
	group by d.Doctor_ID, dp.Medical_Condition
),
DoctorConditionCount as (
	select Doctor_ID,
		   Count(Distinct Medical_Condition) as Condition_count
	from DoctorPatientConditions
	group by Doctor_ID
),
TotalConditions as (
	Select count(distinct Medical_Condition) as Total_Conditions
	from Dim_Patient
)
select dc.Doctor_ID
from DoctorConditionCount as dc,TotalConditions as tc
where dc.Condition_count = tc.Total_Conditions;


-- Q4. What is the average billing amount based on patient gender?

Select dp.Gender,
       Avg(fa.Billing_amount) as Average_billing
from fact_admissions as fa 
join dim_patient as dp ON fa.Patient_ID = dp.Patient_ID
group by dp.Gender;


-- Q5. What is the total Number of paitients categorized by blood type?
Select Blood_type,
       count(distinct Patient_ID) as Total_Patients
from dim_patient
group by Blood_type;


-- Q6. Find out how many patients there are in a condition as medical_condition
select Medical_condition,
	   count(*) as Patient_count
from dim_patient
group by Medical_condition
order by Patient_count desc
limit 10;


-- Q7. which doctor has treated the highest number of patients?
select dd.Doctor_Name,
       count(distinct fa.Patient_ID) as Total_patients
from fact_admissions as fa
join dim_doctor as dd on fa.Doctor_ID = dd.Doctor_ID
group by dd.Doctor_Name
order by Total_patients desc
limit 1;

-- Q8. What is the average billing amount for each hospital?
select dh.Hospital_Name,
	   avg(fa.Billing_amount) as average_billing
from fact_admissions as fa
join dim_hospital dh on fa.Hospital_ID = dh.Hospital_ID
group by dh.Hospital_Name
order by average_billing desc;


-- Q8. Which hospital is associated with the highest revenue?
select dh.Hospital_Name,
	   sum(fa.Billing_amount) as Total_Revenue
from fact_admissions as fa
join dim_hospital dh on fa.Hospital_ID = dh.Hospital_ID
group by dh.Hospital_Name
order by Total_Revenue desc
limit 1;


-- Q9. What is the most frequently used medication?
select dm.Medication_Name,
       count(*) as usage_count
from fact_admissions as fa
join dim_medication as dm on fa.Medication_ID = dm.Medication_ID
group by dm.Medication_Name
order by usage_count desc
limit 1;


-- Q10. Which test results are linked with the highest billing amounts?
select dt.Test_Result,
	   avg(fa.Billing_Amount) as Average_Billing
from fact_admissions as fa
join dim_test_results as dt on fa.Test_Result_ID = dt.Test_Result_ID
group by dt.Test_Result
order by Average_Billing desc;


-- Q11. Which admission type has the highest average billing?
select da.Admission_Type,
       avg(fa.Billing_Amount) as Average_Billing
from fact_admissions as fa
join dim_admission as da on fa.Admission_ID = da.Admission_ID
group by da.Admission_Type
order by Average_Billing desc;








-- Q1. What is the top 3 highest billing amount for each doctor?
-- Donat chart

create view table1 as(
with DoctorBilling as (
select fa.Doctor_ID,
       Doctor_Name,
       sum(billing_amount) as Total_billing
from fact_admissions as fa
join dim_doctor as dd on dd.Doctor_ID = fa.Doctor_ID
group by Doctor_ID
),
RankedDoctor as (
select Doctor_ID,
	   Doctor_Name,
	   Total_billing,
    Rank() Over(order by Total_billing desc) as Ranked
from DoctorBilling
)
select Doctor_ID,Doctor_Name,Total_billing
from RankedDoctor
where Ranked <= 3);


-- Q2. What are the top 3 hospitals with the highest total billing amounts?
-- Suggested Visualization: Bar Chart
CREATE VIEW TopHospitals AS (
    WITH HospitalBilling AS (
        SELECT 
            fa.Hospital_ID, 
            h.Hospital_Name, 
            SUM(fa.Billing_Amount) AS Total_Billing
        FROM Fact_Admissions fa
        JOIN Dim_Hospital h ON fa.Hospital_ID = h.Hospital_ID
        GROUP BY fa.Hospital_ID
    ),
    RankedHospitals AS (
        SELECT 
            Hospital_ID, 
            Hospital_Name, 
            Total_Billing,
            RANK() OVER (ORDER BY Total_Billing DESC) AS Ranked
        FROM HospitalBilling
    )
    SELECT 
        Hospital_ID, 
        Hospital_Name, 
        Total_Billing
    FROM RankedHospitals
    WHERE Ranked <= 3
);




-- Q3. Which doctor has treated the most patients?
-- Suggested Visualization: Table


CREATE VIEW TopDoctors AS (
    SELECT 
        d.Doctor_ID, 
        d.Doctor_Name, 
        COUNT(fa.Patient_ID) AS Total_Patients
    FROM Fact_Admissions fa
    JOIN Dim_Doctor d ON fa.Doctor_ID = d.Doctor_ID
    GROUP BY d.Doctor_ID
    ORDER BY Total_Patients DESC
    LIMIT 10
);


-- Q4. What is the distribution of patients by age group?
-- Suggested Visualization: Pie Chart or Bar Chart

CREATE VIEW AgeGroupDistribution AS (
    SELECT 
        CASE 
            WHEN p.Age BETWEEN 0 AND 18 THEN '0-18'
            WHEN p.Age BETWEEN 19 AND 35 THEN '19-35'
            WHEN p.Age BETWEEN 36 AND 50 THEN '36-50'
            WHEN p.Age BETWEEN 51 AND 70 THEN '51-70'
            ELSE '70+'
        END AS Age_Group,
        COUNT(*) AS Total_Patients
    FROM Dim_Patient p
    JOIN Fact_Admissions fa ON p.Patient_ID = fa.Patient_ID
    GROUP BY Age_Group
);




-- Q5. What is the revenue trend over time?
-- Suggested Visualization: Line Chart

CREATE VIEW RevenueTrend AS (
    SELECT 
        YEAR(Admission_Date) AS Year, 
        MONTHNAME(Admission_Date) AS Month, 
        SUM(Billing_Amount) AS Total_Revenue
    FROM Fact_Admissions
    GROUP BY YEAR(Admission_Date),
    MONTHNAME(Admission_Date)
    ORDER BY Year, Month
);



-- Q6. What is the revenue trend over day?
    SELECT 
        cal.Date,
        SUM(fa.Billing_Amount / DATEDIFF(fa.Discharge_Date, fa.Admission_Date)) AS Daily_Revenue
    FROM Fact_Admissions fa
    JOIN (
        SELECT DISTINCT Admission_Date + INTERVAL n DAY AS Date
        FROM Fact_Admissions, 
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
         UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 
         UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) numbers
    ) cal 
    ON cal.Date BETWEEN fa.Admission_Date AND fa.Discharge_Date
    GROUP BY cal.Date
    ORDER BY cal.Date
;



-- Q7. Which room types are most frequently used?
-- Suggested Visualization: Pie Chart

CREATE VIEW RoomUsage AS (
    SELECT 
        a.Admission_Type, 
        COUNT(fa.Admission_ID) AS Total_Admissions
    FROM Fact_Admissions fa
    JOIN Dim_Admission a ON fa.Admission_ID = a.Admission_ID
    GROUP BY a.Admission_Type
    ORDER BY Total_Admissions DESC
);
