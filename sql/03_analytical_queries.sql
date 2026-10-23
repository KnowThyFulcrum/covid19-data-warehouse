-- 1. Top 15 countries by total cases ever
SELECT TOP 15
    l.country, MAX(c.total_cases) AS total_cases
FROM Fact_Daily_COVID f
    JOIN Dim_Location l ON f.location_id = l.location_id
    JOIN Dim_Case c ON f.case_id = c.case_id
GROUP BY l.country
ORDER BY total_cases DESC;

-- 2. Peak 7-day average new cases by country (waves)
SELECT l.country, MAX(c.new_cases_smoothed) AS peak_daily_cases, d.date
FROM Fact_Daily_COVID f
    JOIN Dim_Location l ON f.location_id = l.location_id
    JOIN Dim_Case c ON f.case_id = c.case_id
    JOIN Dim_Date d ON f.date_id = d.date_id
GROUP BY l.country, d.date
ORDER BY peak_daily_cases DESC;

-- 3. Case Fatality Rate (CFR) per country (latest available)
SELECT l.country,
    MAX(c.total_cases) AS total_cases,
    MAX(dth.total_deaths) AS total_deaths,
    ROUND(100.0 * MAX(dth.total_deaths) / NULLIF(MAX(c.total_cases),0), 3) AS CFR_pct
FROM Fact_Daily_COVID f
    JOIN Dim_Location l ON f.location_id = l.location_id
    JOIN Dim_Case c ON f.case_id = c.case_id
    JOIN Dim_Death dth ON f.death_id = dth.death_id
GROUP BY l.country
HAVING MAX(c.total_cases) > 100000
ORDER BY CFR_pct DESC;

-- 4. Vaccination impact — cases before vs after 50% fully vaccinated
WITH
    VaccMilestone
    AS
    (
        SELECT location_id, MIN(d.date) AS milestone_date
        FROM Fact_Daily_COVID f
            JOIN Dim_Vaccination v ON f.vaccinated_id = v.vaccinated_id
            JOIN Dim_Date d ON f.date_id = d.date_id
        WHERE v.people_fully_vaccinated_per_hundred >= 50
        GROUP BY location_id
    )
SELECT l.country,
    AVG(CASE WHEN d.date < vm.milestone_date THEN c.new_cases_smoothed END) AS cases_before_50pct,
    AVG(CASE WHEN d.date >= vm.milestone_date THEN c.new_cases_smoothed END) AS cases_after_50pct
FROM VaccMilestone vm
    JOIN Fact_Daily_COVID f ON f.location_id = vm.location_id
    JOIN Dim_Date d ON f.date_id = d.date_id
    JOIN Dim_Location l ON f.location_id = l.location_id
    LEFT JOIN Dim_Case c ON f.case_id = c.case_id
GROUP BY l.country
HAVING AVG(CASE WHEN d.date < vm.milestone_date THEN c.new_cases_smoothed END) > 10;

-- 5. Countries with highest excess mortality (2020-2025)
SELECT TOP 15
    l.country,
    MAX(dth.excess_mortality_cumulative) AS excess_mortality_pct,
    MAX(dth.excess_mortality_cumulative_absolute) AS excess_deaths_absolute
FROM Fact_Daily_COVID f
    JOIN Dim_Location l ON f.location_id = l.location_id
    JOIN Dim_Death dth ON f.death_id = dth.death_id
WHERE dth.excess_mortality_cumulative IS NOT NULL
GROUP BY l.country
ORDER BY excess_mortality_pct DESC;

-- 6. Testing positivity rate (7-day average) – highest peaks
SELECT TOP 15
    l.country,
    d.date,
    ROUND(t.tests_per_case, 2) AS tests_per_case,
    ROUND(100.0 / NULLIF(t.tests_per_case,0), 2) AS positivity_rate_pct
FROM Fact_Daily_COVID f
    JOIN Dim_Location l ON f.location_id = l.location_id
    JOIN Dim_Test t ON f.test_id = t.test_id
    JOIN Dim_Date d ON f.date_id = d.date_id
WHERE t.tests_per_case IS NOT NULL
ORDER BY positivity_rate_pct DESC;

-- 7. Fastest vaccination rollouts – days to reach 70% fully vaccinated
WITH
    Vacc70
    AS
    (
        SELECT
            f.location_id,
            MIN(d.date) AS date_70pct
        FROM Fact_Daily_COVID f
            JOIN Dim_Vaccination v ON f.vaccinated_id = v.vaccinated_id
            JOIN Dim_Date d ON f.date_id = d.date_id
        WHERE v.people_fully_vaccinated_per_hundred >= 70
        GROUP BY f.location_id
    )
SELECT
    l.country,
    v70.date_70pct,
    DATEDIFF(DAY, '2020-12-01', v70.date_70pct) AS days_since_first_vaccines
FROM Vacc70 v70
    JOIN Dim_Location l ON v70.location_id = l.location_id
ORDER BY days_since_first_vaccines ASC;

-- 8. Reproduction rate (R) above 2.0 for longest consecutive periods
WITH
    RStreak
    AS
    (
        SELECT
            l.country,
            d.date,
            f.reproduction_rate,
            ROW_NUMBER() OVER (PARTITION BY l.country ORDER BY d.date) 
        - ROW_NUMBER() OVER (PARTITION BY l.country, CASE WHEN f.reproduction_rate > 2 THEN 1 ELSE 0 END ORDER BY d.date) AS streak_group
        FROM Fact_Daily_COVID f
            JOIN Dim_Location l ON f.location_id = l.location_id
            JOIN Dim_Date d ON f.date_id = d.date_id
        WHERE f.reproduction_rate > 2
    )
SELECT TOP 10
    country,
    COUNT(*) AS consecutive_days_above_2,
    MIN(date) AS streak_start,
    MAX(date) AS streak_end
FROM RStreak
GROUP BY country, streak_group
ORDER BY consecutive_days_above_2 DESC;

-- 9. Monthly new cases per million inhabitants – 2021 vs 2022 comparison
SELECT
    l.country,
    DATEPART(YEAR, d.date) AS year,
    DATEPART(MONTH, d.date) AS month,
    AVG(c.new_cases_per_million) AS avg_daily_cases_per_million
FROM Fact_Daily_COVID f
    JOIN Dim_Date d ON f.date_id = d.date_id
    JOIN Dim_Location l ON f.location_id = l.location_id
    JOIN Dim_Case c ON f.case_id = c.case_id
WHERE DATEPART(YEAR, d.date) IN (2021, 2022)
GROUP BY l.country, DATEPART(YEAR, d.date), DATEPART(MONTH, d.date)
HAVING AVG(c.new_cases_per_million) > 50
ORDER BY country, year, month;

-- 10. Hospital & ICU occupancy peaks
SELECT TOP 15
    l.country,
    d.date,
    hp.hospital_patients,
    hp.icu_patients,
    ROUND(hp.hospital_patients_per_million, 1) AS hospital_per_million,
    ROUND(hp.icu_patients_per_million, 1) AS icu_per_million
FROM Fact_Daily_COVID f
    JOIN Dim_Location l ON f.location_id = l.location_id
    JOIN Dim_HospitalPatient hp ON f.patient_id = hp.patient_id
    JOIN Dim_Date d ON f.date_id = d.date_id
WHERE hp.hospital_patients_per_million IS NOT NULL
ORDER BY hp.hospital_patients_per_million DESC;
