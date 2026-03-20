# dbt-course (Hiring Analytics)

This repository contains:

- **CSV seed data** under `data/` (candidates, employees, interviews, job_functions, skills).
- **`scripts/snowflake_ingest.py`** — loads files into Snowflake `dbt_project.raw`.
- **dbt Core project `hiring_analytics`** — models under `models/`; seeds point at `data/`.

## Prerequisites

- Python 3.11+ recommended
- Snowflake account and credentials (via **environment variables** only — do not commit secrets)

## Quick start — dbt Core (homework Task 1)

### 1. Virtual environment

From the repo root:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 2. Snowflake profile (`~/.dbt/profiles.yml`)

- **Option A:** run the helper (no passwords stored in the repo):

  ```powershell
  python scripts/setup_environment.py
  ```

- **Option B:** copy `profiles.yml.example` to `%USERPROFILE%\.dbt\profiles.yml` and ensure the profile name is **`hiring_analytics`**.

**Using a `.env` file:** dbt does **not** read `.env` by itself. If your Snowflake vars are in repo-root `.env`, use:

```powershell
python scripts/dbt_env.py debug
python scripts/dbt_env.py seed
```

Or set env vars in the shell before plain `dbt`:

```powershell
$env:SNOW_ACCOUNT = "your_account"
$env:SNOW_USER = "your_user"
$env:SNOW_USER_PASSWORD = "your_password"
# Optional overrides:
# $env:SNOWFLAKE_ROLE = "YOUR_ROLE"
# $env:SNOWFLAKE_DATABASE = "dbt_project"
# $env:SNOWFLAKE_WAREHOUSE = "COMPUTE_WH"
```

**Course note:** the default dbt schema in the profile is **`dev`**, not `raw`. The `raw` schema is for ingested tables only.

### 3. Verify dbt

```powershell
dbt debug
dbt seed
```

### 4. Optional — pre-commit + sqlfmt

```powershell
pre-commit install
```

Hooks are defined in `.pre-commit-config.yaml`. SQL formatter package: **`shandy-sqlfmt`** (`sqlfmt` on PATH).

---

## Load raw data (ingestion script)

Same env vars as above. From repo root:

```powershell
pip install -r scripts/requirements.txt   # pandas, snowflake-connector-python, python-dotenv
python scripts/snowflake_ingest.py .\data
```

This creates/use database **`dbt_project`**, schema **`raw`**, and loads the CSVs.

---

## Task 2 — automated setup (optional)

`scripts/setup_environment.py`:

- Creates `.venv` (unless `--skip-venv`) and installs `requirements.txt`
- Ensures `%USERPROFILE%\.dbt\profiles.yml` exists
- Appends the `hiring_analytics` profile **only if it is missing**
- Runs `pre-commit install` unless `--no-pre-commit`

**Security:** credentials are never written to disk by this script — only `env_var(...)` placeholders in YAML.

```powershell
python scripts/setup_environment.py
```

---

## Project layout

| Path | Purpose |
|------|--------|
| `dbt_project.yml` | dbt project config (`profile: hiring_analytics`, `seed-paths: ["data"]`) |
| `models/` | dbt models (`example/`, `staging/`, `marts/`) |
| `data/` | Seed CSVs |
| `profiles.yml.example` | Template for `~/.dbt/profiles.yml` |
| `requirements.txt` | dbt + optional dev tools |

---

## Homework checklist

- [x] Python venv + `dbt-core`, `dbt-snowflake`, optional `pre-commit`, `shandy-sqlfmt`
- [x] `dbt init`–equivalent project at repo root (`hiring_analytics`), default schema **`dev`** in profile
- [x] `dbt_project.yml` configured; run `dbt debug` and `dbt seed` after setting env vars
- [x] `.gitignore`: `.venv`, `target`, `dbt_packages`, logs, IDE dirs, `.env`
- [ ] **Commit and push your work** (Task 1 #8)
- [ ] (Optional) Use / extend `scripts/setup_environment.py` for Task 2
