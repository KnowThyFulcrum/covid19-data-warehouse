-- 1. Dim_Date
CREATE TABLE Dim_Date
(
    date_id INT IDENTITY(1,1) PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    year INT NOT NULL,
    month INT NOT NULL,
    day INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter INT NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(10) NOT NULL,
    is_weekend BIT NOT NULL
);
GO

-- 2. Dim_Location
CREATE TABLE Dim_Location
(
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    country VARCHAR(100) NOT NULL,
    continent VARCHAR(50),
    population BIGINT,
    population_density DECIMAL(12,6),
    median_age DECIMAL(6,3),
    life_expectancy DECIMAL(8,4)
);
GO

-- 3. Dim_Case
CREATE TABLE Dim_Case
(
    case_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    total_cases BIGINT,
    total_cases_per_million DECIMAL(18,6),
    new_cases INT,
    new_cases_per_million DECIMAL(15,6),
    new_cases_smoothed DECIMAL(15,6),
    new_cases_smoothed_per_million DECIMAL(15,6)
);
GO

-- 4. Dim_Death
CREATE TABLE Dim_Death
(
    death_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    total_deaths INT,
    total_deaths_per_million DECIMAL(18,6),
    new_deaths INT,
    new_deaths_per_million DECIMAL(15,6),
    new_deaths_smoothed DECIMAL(15,6),
    new_deaths_smoothed_per_million DECIMAL(15,6),
    excess_mortality DECIMAL(12,6),
    excess_mortality_cumulative DECIMAL(12,6),
    excess_mortality_cumulative_absolute DECIMAL(18,2),
    excess_mortality_cumulative_per_million DECIMAL(18,6)
);
GO

-- 5. Dim_HospitalPatient
CREATE TABLE Dim_HospitalPatient
(
    patient_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    hospital_patients INT,
    hospital_patients_per_million DECIMAL(18,6),
    icu_patients INT,
    icu_patients_per_million DECIMAL(18,6)
);
GO

-- 6. Dim_Vaccination
CREATE TABLE Dim_Vaccination
(
    vaccinated_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    total_vaccinations BIGINT,
    people_vaccinated BIGINT,
    people_fully_vaccinated BIGINT,
    total_boosters BIGINT,
    new_vaccinations INT,
    new_vaccinations_smoothed INT,
    total_vaccinations_per_hundred DECIMAL(10,4),
    people_vaccinated_per_hundred DECIMAL(10,4),
    people_fully_vaccinated_per_hundred DECIMAL(10,4),
    total_boosters_per_hundred DECIMAL(10,4),
    new_vaccinations_smoothed_per_million DECIMAL(12,4),
    new_people_vaccinated_smoothed BIGINT,
    new_people_vaccinated_smoothed_per_hundred DECIMAL(10,4)
);
GO

-- 7. Dim_Test
CREATE TABLE Dim_Test
(
    test_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    total_tests BIGINT,
    new_tests BIGINT,
    total_tests_per_thousand DECIMAL(15,6),
    new_tests_per_thousand DECIMAL(15,6),
    new_tests_smoothed BIGINT,
    new_tests_smoothed_per_thousand DECIMAL(15,6),
    tests_per_case DECIMAL(15,6)
);
GO

-- 8. Fact_Daily_COVID (main fact table)
CREATE TABLE Fact_Daily_COVID
(
    daily_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    date_id INT NOT NULL,
    location_id INT NOT NULL,

    case_id BIGINT NULL,
    death_id BIGINT NULL,
    patient_id BIGINT NULL,
    vaccinated_id BIGINT NULL,
    test_id BIGINT NULL,

    reproduction_rate DECIMAL(8,4) NULL,

    CONSTRAINT FK_Fact_Daily_Date FOREIGN KEY (date_id) REFERENCES Dim_Date(date_id),
    CONSTRAINT FK_Fact_Daily_Location FOREIGN KEY (location_id) REFERENCES Dim_Location(location_id),

    CONSTRAINT FK_Fact_Case FOREIGN KEY (case_id) REFERENCES Dim_Case(case_id),
    CONSTRAINT FK_Fact_Death FOREIGN KEY (death_id) REFERENCES Dim_Death(death_id),
    CONSTRAINT FK_Fact_Hospital FOREIGN KEY (patient_id) REFERENCES Dim_HospitalPatient(patient_id),
    CONSTRAINT FK_Fact_Vaccination FOREIGN KEY (vaccinated_id) REFERENCES Dim_Vaccination(vaccinated_id),
    CONSTRAINT FK_Fact_Test FOREIGN KEY (test_id) REFERENCES Dim_Test(test_id),

    CONSTRAINT UQ_Fact_Daily_Date_Location UNIQUE (date_id, location_id)
);
GO