INSERT INTO Dim_Location
    (
    country, continent, population, population_density,
    median_age, life_expectancy
    )
SELECT DISTINCT
    country,
    continent,
    population,
    population_density,
    median_age,
    life_expectancy
FROM CovidProject
WHERE country IS NOT NULL
ORDER BY country;
GO

INSERT INTO Dim_Case
    (
    total_cases, total_cases_per_million, new_cases, new_cases_per_million,
    new_cases_smoothed, new_cases_smoothed_per_million
    )
SELECT DISTINCT
    total_cases,
    total_cases_per_million,
    new_cases,
    new_cases_per_million,
    new_cases_smoothed,
    new_cases_smoothed_per_million
FROM CovidProject
WHERE total_cases IS NOT NULL OR new_cases IS NOT NULL;
GO

INSERT INTO Dim_Death
    (
    total_deaths, total_deaths_per_million, new_deaths, new_deaths_per_million,
    new_deaths_smoothed, new_deaths_smoothed_per_million,
    excess_mortality, excess_mortality_cumulative,
    excess_mortality_cumulative_absolute, excess_mortality_cumulative_per_million
    )
SELECT DISTINCT
    total_deaths,
    total_deaths_per_million,
    new_deaths,
    new_deaths_per_million,
    new_deaths_smoothed,
    new_deaths_smoothed_per_million,
    excess_mortality,
    excess_mortality_cumulative,
    excess_mortality_cumulative_absolute,
    excess_mortality_cumulative_per_million
FROM CovidProject
WHERE total_deaths IS NOT NULL OR new_deaths IS NOT NULL;
GO

INSERT INTO Dim_HospitalPatient
    (
    hospital_patients, hospital_patients_per_million,
    icu_patients, icu_patients_per_million
    )
SELECT DISTINCT
    hospital_patients,
    hospital_patients_per_million,
    icu_patients,
    icu_patients_per_million
FROM CovidProject
WHERE hospital_patients IS NOT NULL OR icu_patients IS NOT NULL;
GO

INSERT INTO Dim_Vaccination
    (
    total_vaccinations, people_vaccinated, people_fully_vaccinated,
    total_boosters, new_vaccinations, new_vaccinations_smoothed,
    total_vaccinations_per_hundred, people_vaccinated_per_hundred,
    people_fully_vaccinated_per_hundred, total_boosters_per_hundred,
    new_vaccinations_smoothed_per_million,
    new_people_vaccinated_smoothed, new_people_vaccinated_smoothed_per_hundred
    )
SELECT DISTINCT
    total_vaccinations, people_vaccinated, people_fully_vaccinated,
    total_boosters, new_vaccinations, new_vaccinations_smoothed,
    total_vaccinations_per_hundred, people_vaccinated_per_hundred,
    people_fully_vaccinated_per_hundred, total_boosters_per_hundred,
    new_vaccinations_smoothed_per_million,
    new_people_vaccinated_smoothed, new_people_vaccinated_smoothed_per_hundred
FROM CovidProject
WHERE total_vaccinations IS NOT NULL OR new_vaccinations IS NOT NULL;
GO

INSERT INTO Dim_Test
    (
    total_tests, new_tests, total_tests_per_thousand,
    new_tests_per_thousand, new_tests_smoothed,
    new_tests_smoothed_per_thousand, tests_per_case
    )
SELECT DISTINCT
    total_tests, new_tests, total_tests_per_thousand,
    new_tests_per_thousand, new_tests_smoothed,
    new_tests_smoothed_per_thousand, tests_per_case
FROM CovidProject
WHERE total_tests IS NOT NULL OR new_tests IS NOT NULL;
GO

WITH
    CovidProject
    AS
    (
                    SELECT CAST('2020-01-01' AS DATE) AS dt
        UNION ALL
            SELECT DATEADD(DAY, 1, dt)
            FROM CovidProject
            WHERE dt < '2025-12-31'
    )
INSERT INTO Dim_Date
    (
    date, year, month, day, month_name, quarter,
    day_of_week, day_name, is_weekend
    )
SELECT DISTINCT
    dt AS date,
    YEAR(dt) year,
    MONTH(dt) month,
    DAY(dt) day,
    DATENAME(MONTH, dt) month_name,
    DATEPART(QUARTER, dt) quarter,
    DATEPART(WEEKDAY, dt) day_of_week,
    DATENAME(WEEKDAY, dt) day_name,
    CASE WHEN DATEPART(WEEKDAY, dt) IN (1,7) THEN 1 ELSE 0 END is_weekend
FROM CovidProject
OPTION
(MAXRECURSION
0);
GO

INSERT INTO Fact_Daily_COVID
    (
    date_id,
    location_id,
    case_id,
    death_id,
    patient_id,
    vaccinated_id,
    test_id,
    reproduction_rate
    )
SELECT
    d.date_id,
    l.location_id,
    MAX(c.case_id)       AS case_id,
    MAX(dth.death_id)    AS death_id,
    MAX(hp.patient_id)   AS patient_id,
    MAX(v.vaccinated_id) AS vaccinated_id,
    MAX(t.test_id)       AS test_id,
    MAX(s.reproduction_rate) AS reproduction_rate
FROM CovidProject s
    INNER JOIN Dim_Date d ON d.date = s.date
    INNER JOIN Dim_Location l ON l.country = s.country
    LEFT JOIN Dim_Case c ON c.total_cases = s.total_cases
        AND ISNULL(c.new_cases,0) = ISNULL(s.new_cases,0)
        AND ISNULL(c.new_cases_smoothed,0) = ISNULL(s.new_cases_smoothed,0)
    LEFT JOIN Dim_Death dth ON ISNULL(dth.total_deaths,0) = ISNULL(s.total_deaths,0)
        AND ISNULL(dth.new_deaths,0) = ISNULL(s.new_deaths,0)
    LEFT JOIN Dim_HospitalPatient hp ON ISNULL(hp.hospital_patients,0) = ISNULL(s.hospital_patients,0)
    LEFT JOIN Dim_Vaccination v ON ISNULL(v.total_vaccinations,0) = ISNULL(s.total_vaccinations,0)
    LEFT JOIN Dim_Test t ON ISNULL(t.total_tests,0) = ISNULL(s.total_tests,0)
GROUP BY 
    d.date_id,
    l.location_id;
GO