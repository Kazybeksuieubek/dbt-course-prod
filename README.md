# dbt-course

This repository contains seed data and an initial ingestion script to set up the `raw` schema in the `dbt_project` database within your Snowflake account.

## 📦 Contents

The dataset includes five main entities:

* `candidates`
* `employees` (also known as interviewers)
* `interviews`
* `job_functions`
* `skills`

## 🚀 Getting Started

To load the data into Snowflake, follow these steps:

### 1. Set Required Environment Variables

Make sure the following environment variables are defined:

* `SNOW_ACCOUNT` – your Snowflake account identifier
* `SNOW_USER` – your Snowflake username
* `SNOW_USER_PASSWORD` – your Snowflake password

These are required for authenticating with Snowflake.

### 2. Run the Ingestion Script

Use the provided script to load data:

```bash
python scripts/snowflake_ingest.py /path/to/data/folder
```

Replace `/path/to/data/folder` with the path to your local folder containing the CSV data files.

The script will:

* Connect to your Snowflake instance
* Create the `dbt_project` database, `raw` schema and required tables
* Load the data into the corresponding tables

