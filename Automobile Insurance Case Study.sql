CREATE DATABASE Autoinsurance_claims

-- Q1 Calculate the proportion of claim spend on injury, property and vehicle (total)

SELECT 
ROUND(SUM(injury_claim)*100/SUM(total_claim_amount),2) AS injury_proportion,
ROUND(SUM(property_claim)*100/SUM(total_claim_amount),2) AS property_proportion,
ROUND(SUM(vehicle_claim)*100/SUM(total_claim_amount),2) AS vehicle_proportion
FROM claims;

-- Q2 Calculate the proportion of claim spend on injury, property and vehicle (for top 10 total claims)

WITH CTE AS
(SELECT policy_number,injury_claim, property_claim, vehicle_claim, total_claim_amount, DENSE_RANK() OVER(ORDER BY total_claim_amount DESC) AS rank_
FROM claims)
SELECT
ROUND(SUM(injury_claim)*100/SUM(total_claim_amount),2) AS injury_proportion,
ROUND(SUM(property_claim)*100/SUM(total_claim_amount),2) AS property_proportion,
ROUND(SUM(vehicle_claim)*100/SUM(total_claim_amount),2) AS vehicle_proportion,rank_
FROM CTE
GROUP BY policy_number,rank_
HAVING rank_ < 11
ORDER BY rank_;

-- Q3 Create a visualization that provides a breakdown between the male and female insurers, 
--along with education level each year, starting from 1990.

SELECT insured_education_level, YEAR(policy_bind_date) AS _year, insured_sex, COUNT(insured_sex) AS total_number
FROM claims
WHERE YEAR(policy_bind_date) >=1990
GROUP BY insured_sex,insured_education_level,YEAR(policy_bind_date)
ORDER BY insured_sex,insured_education_level,YEAR(policy_bind_date)

-- Q4 Compare the number of insurers regionwise

SELECT policy_state, COUNT(policy_number) AS count_per_region
FROM claims
GROUP BY policy_state
ORDER BY count_per_region

-- Q5 Comment on the relationship between deductible and premium.

-- CORRELATION COEFF = COV(X1,X2)/[STD(X1)*STD(X2)]
-- COV = AVG((X1-X1.mu)*(X2-X2.mu))
-- VAR = AVG((X1-X1.mu)**2)
-- STDDEV = SQRT(AVG((X1-X1.mu)**2))

	WITH MEAN AS
	(SELECT
	policy_deductible,policy_annual_premium,
	AVG(policy_deductible) OVER() AS ded_mean,AVG(policy_annual_premium) OVER () AS premium_mean
	FROM claims
	),
	VARIANCE AS
	(
	SELECT
	AVG(POWER(policy_deductible-ded_mean,2)) AS ded_var,
	AVG(POWER(policy_annual_premium-premium_mean,2)) AS premium_var
	FROM MEAN
	),
	STDDEV AS
	(
	SELECT
	POWER(ded_var,0.5) AS ded_stddev,
	POWER(premium_var,0.5) AS premium_stddev
	FROM VARIANCE
	),
	COVARIANCE AS
	(
	SELECT
	AVG((policy_deductible-ded_mean)*(policy_annual_premium-premium_mean)) AS COV_ded_premium
	FROM MEAN
	)
	SELECT
	ROUND(COV_ded_premium/(ded_stddev*premium_stddev),5) AS CORR_ded_premium
	FROM COVARIANCE,STDDEV;

-- CORRELATION COEFFICIENT = -0.00325. HENCE, WEAK CORRELATION BETWEEN DED AND PREMIUM

-- Q6 Which date had the maximum number of accidents?
SELECT TOP 1 incident_date, COUNT(incident_type) AS number_of_accidents
FROM claims
WHERE incident_type != 'Vehicle Theft'
GROUP BY incident_date
ORDER BY number_of_accidents DESC

-- Q7 Which age group is most likely to meet an accident?

SELECT
CASE
WHEN age <= 29 THEN '19-29'
WHEN age <= 39 THEN '30-39'
WHEN age <= 49 THEN '40-49'
WHEN age <= 59 THEN '50-59'
ELSE 'above 59'
END AS age_group, COUNT(*) AS total_number
FROM claims
WHERE incident_type LIKE '%Collision%'
GROUP BY
CASE
WHEN age <= 29 THEN '19-29'
WHEN age <= 39 THEN '30-39'
WHEN age <= 49 THEN '40-49'
WHEN age <= 59 THEN '50-59'
ELSE 'above 59'
END
ORDER BY total_number DESC;

-- Q8 Compare capital gain and capital loss and comment on profit.

SELECT SUM(capital_gains) AS total_gains, SUM(capital_loss) AS total_loss,
(SUM(capital_gains)-SUM(capital_loss)) AS profit
FROM claims

-- Q9 Are females more likely to take benefit of automobile insurance?

SELECT 
SUM(CASE WHEN insured_sex = 'MALE' THEN 1 ELSE 0 END) AS male_count,
SUM(CASE WHEN insured_sex = 'FEMALE' THEN 1 ELSE 0 END) AS female_count
FROM claims;

-- Q10 Which auto making company had the most accidents?

SELECT TOP 1 auto_make, COUNT(auto_make) AS count_brand
FROM claims
WHERE incident_type LIKE '%Collision%'
GROUP BY auto_make
ORDER BY count_brand DESC

