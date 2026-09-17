# StreamCart — dbt Core Project

An end-to-end **dbt Core data transformation project** for StreamCart using nested JSON data.

## Tech Stack

* dbt Core
* Snowflake / Databricks
* SQL & Jinja
* Git & GitHub

## Pipeline

```text
Raw JSON → Staging → Intermediate → Mart
```

## Key Concepts

* JSON flattening & data cleaning
* Sources & materializations
* Jinja & custom macros
* dbt_utils & dbt_expectations
* KPI models
* Incremental models
* Seeds & reference data
* Snapshots (SCD Type 2)
* Data quality testing
* Hooks & documentation

## Project Structure

```text
models/
├── staging/
├── intermediate/
└── marts/
macros/
seeds/
snapshots/
tests/
dbt_project.yml
packages.yml
```

## Run

```bash
dbt deps
dbt seed
dbt build
dbt snapshot
dbt docs generate
```

## Author

**Tamanna Malviya**
