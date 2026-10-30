# COVID-19 Pandemic Analytics Data Warehouse (Azure SQL)

A Kimball-style star schema data warehouse for global COVID-19 analytics. It transforms the flat, wide Our World in Data (OWID) dataset into one fact table and seven dimension tables on Azure SQL Database.

**Course:** CAI 5867 – Advanced Data Engineering, Florida International University (Fall 2025)

## Tools
Azure SQL Database · T-SQL · Dimensional modeling (Kimball) · dbdiagram.io

## Methods
- Analyzed the OWID dataset (daily metrics for 200+ countries, 2020 onward): sparse, high-cardinality metric groups (cases, deaths, hospitalizations, testing, vaccination, excess mortality, reproduction rate, demographics).
- Designed a normalized 3NF model (`diagrams/erd_3nf.dbml`) and the final **star schema**: `Fact_Daily_COVID` plus 7 dimensions: `Dim_Date`, `Dim_Location`, `Dim_Case`, `Dim_Death`, `Dim_HospitalPatient`, `Dim_Vaccination`, `Dim_Test`.
- ETL: loaded data into staging, built the dimensions, then did the final fact load with `GROUP BY (date_id, location_id)` and `MAX(surrogate_key)` to remove duplicate (country, date) rows and avoid UNIQUE-constraint violations (TRUNCATE + GROUP BY + MAX pattern).

## Results
- Final model: **exactly 50,000 fact rows with 100% referential integrity**.
- Supports complex analytical queries across cases, deaths, testing, vaccination rollout, excess mortality, and reproduction rate, with sub-second response on simple star-schema joins.

## Repository structure
```
sql/01_create_tables.sql        DDL: dimension and fact tables
sql/02_insert_load.sql          ETL / load statements
sql/03_analytical_queries.sql   Example analytical queries
diagrams/erd_3nf.dbml           3NF model (paste into dbdiagram.io)
diagrams/erd_star_schema.png    Star schema ERD
docs/final_documentation.pdf    Final report
docs/presentation.pptx          Presentation
```

## Dataset
[Our World in Data — COVID-19 dataset](https://github.com/owid/covid-19-data/tree/master/public/data) (`owid-covid-data.csv`). It is not included because of size.

## How to run
1. Create an Azure SQL Database, or use any SQL Server instance.
2. Import the OWID CSV into a staging table named `CovidProject`, for example with the Azure Data Studio / SSMS Import Flat File wizard.
3. Run `sql/01_create_tables.sql`, then `sql/02_insert_load.sql`, then `sql/03_analytical_queries.sql`.

## Author
Jay Cespedes
