# Hiring Analytics — dbt Core project

This repository supports the **Hiring Analytics / dbt Fundamentals** initial setup: dbt Core against Snowflake, seed data, optional ingestion into a `raw` schema, and optional automation scripts.

## Contents

| Area | Description |
|------|-------------|
| `data/` | CSV seed files: candidates, employees, interviews, job_functions, skills |
| `dbt_project.yml` | dbt project **`hiring_analytics`**, `seed-paths: ["data"]`, models under `models/` |
| `scripts/snowflake_ingest.py` | Loads `data/` into Snowflake database **`dbt_project`**, schema **`raw`** |
| `profiles.yml.example` | Snowflake profile template; credentials via **`env_var()`** only (no secrets in repo) |
| `scripts/dbt_env.py` | Loads repo `.env` then invokes dbt (dbt does not read `.env` natively) |
| `scripts/setup_environment.py` | Optional bootstrap: venv, `profiles.yml` merge, `pre-commit install` |
| `.pre-commit-config.yaml` | Optional hooks (whitespace, EOF, **sqlfmt**) |

**Security:** `.env` is gitignored. Reviewers should confirm no credentials appear in history or files.

---

## Implementation notes (for reviewers)

- **dbt Core + `dbt-snowflake`** are listed in `requirements.txt` (with `python-dotenv`, optional `pre-commit`, `shandy-sqlfmt`).
- **Default dbt schema** in the profile template is **`dev`**, not `raw`, per course guidance (`raw` is reserved for ingested landing tables).
- **`.gitignore`** covers virtualenv (`.venv/`), dbt artifacts (`target/`, `dbt_packages/`, `logs/`), IDE paths, and `.env`.
- **Task 2 (optional):** `setup_environment.py` creates or augments `%USERPROFILE%\.dbt\profiles.yml` without embedding passwords—only `env_var(...)` placeholders.

---

## Clone and verify (local)

**Requirements:** Python 3.11+ recommended, Snowflake access, environment variables as in `profiles.yml.example` / `.env.example`.

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

**Profile:** Copy `profiles.yml.example` to `%USERPROFILE%\.dbt\profiles.yml` **or** run `python scripts/setup_environment.py`. The active profile name must be **`hiring_analytics`**.

**Connection check** (after setting `SNOW_ACCOUNT`, `SNOW_USER`, `SNOW_USER_PASSWORD`, and optional `SNOWFLAKE_*`):

```powershell
dbt debug
dbt seed
```

If credentials are only in `.env`, use:

```powershell
python scripts/dbt_env.py debug
python scripts/dbt_env.py seed
```

**Optional:** `pre-commit install` — formatters defined in `.pre-commit-config.yaml`.

---

## Raw data load (ingestion)

From repo root, with the same Snowflake env vars (or `.env` loaded by the script):

```powershell
pip install -r scripts/requirements.txt
python scripts/snowflake_ingest.py .\data
```

---

## Repository layout (reference)

| Path | Purpose |
|------|---------|
| `models/example/` | Starter dbt models from project initialization |
| `models/staging/`, `models/marts/` | Placeholders for layered modeling |
| `analyses/`, `tests/`, `macros/`, `snapshots/` | Standard dbt directories |
| `.env.example` | Non-secret template for local env files |

---

## Maintainer

Submissions and course delivery: see the course platform for the fork / student repository URL.
