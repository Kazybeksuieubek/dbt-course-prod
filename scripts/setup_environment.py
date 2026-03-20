#!/usr/bin/env python3
"""
Task 2 (optional): automate dev setup without secrets in the repo.

- Creates a local Python venv and installs requirements.txt (dbt, pre-commit, sqlfmt).
- Ensures ~/.dbt exists and profiles.yml exists.
- Appends the `hiring_analytics` profile block only if that profile is missing.

Security: all Snowflake connection values are read from environment variables at runtime by dbt
(env_var in YAML). Never paste passwords into this script or into Git.
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
REQUIREMENTS = REPO_ROOT / "requirements.txt"

PROFILE_BLOCK = """
# --- hiring_analytics (added by setup_environment.py) ---
hiring_analytics:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOW_ACCOUNT') }}"
      user: "{{ env_var('SNOW_USER') }}"
      password: "{{ env_var('SNOW_USER_PASSWORD') }}"
      role: "{{ env_var('SNOWFLAKE_ROLE', 'ACCOUNTADMIN') }}"
      database: "{{ env_var('SNOWFLAKE_DATABASE', 'dbt_project') }}"
      warehouse: "{{ env_var('SNOWFLAKE_WAREHOUSE', 'COMPUTE_WH') }}"
      schema: dev
      threads: 4
"""


def dbt_user_dir() -> Path:
    home = Path.home()
    return home / ".dbt"


def run(cmd: list[str], cwd: Path | None = None) -> None:
    print("+", " ".join(cmd))
    subprocess.check_call(cmd, cwd=str(cwd) if cwd else None)


def ensure_venv(venv_dir: Path, skip_venv: bool) -> Path:
    if skip_venv:
        py = Path(sys.executable)
        run([str(py), "-m", "pip", "install", "--upgrade", "pip"], cwd=REPO_ROOT)
        if REQUIREMENTS.exists():
            run([str(py), "-m", "pip", "install", "-r", str(REQUIREMENTS)], cwd=REPO_ROOT)
        return py

    py = venv_dir / "Scripts" / "python.exe" if os.name == "nt" else venv_dir / "bin" / "python"
    if not py.exists():
        run([sys.executable, "-m", "venv", str(venv_dir)], cwd=REPO_ROOT)
    run([str(py), "-m", "pip", "install", "--upgrade", "pip"], cwd=REPO_ROOT)
    if REQUIREMENTS.exists():
        run([str(py), "-m", "pip", "install", "-r", str(REQUIREMENTS)], cwd=REPO_ROOT)
    return py


def ensure_profiles(profile_marker: str = "hiring_analytics:") -> None:
    dbt_dir = dbt_user_dir()
    dbt_dir.mkdir(parents=True, exist_ok=True)
    profiles = dbt_dir / "profiles.yml"

    if not profiles.exists():
        profiles.write_text(PROFILE_BLOCK.strip() + "\n", encoding="utf-8")
        print(f"Created {profiles}")
        return

    text = profiles.read_text(encoding="utf-8")
    if profile_marker in text:
        print(f"Profile block already present in {profiles}")
        return

    with profiles.open("a", encoding="utf-8") as f:
        f.write("\n" + PROFILE_BLOCK)
    print(f"Appended hiring_analytics profile to {profiles}")


def optional_pre_commit(py: Path) -> None:
    pre_commit = REPO_ROOT / ".pre-commit-config.yaml"
    if not pre_commit.exists():
        return
    try:
        run([str(py), "-m", "pre_commit", "install"], cwd=REPO_ROOT)
    except subprocess.CalledProcessError as e:
        print("pre-commit install failed (optional):", e, file=sys.stderr)


def main() -> int:
    parser = argparse.ArgumentParser(description="Bootstrap dbt dev environment (no secrets stored).")
    parser.add_argument(
        "--skip-venv",
        action="store_true",
        help="Do not create .venv; use current interpreter for pip install only.",
    )
    parser.add_argument(
        "--no-pre-commit",
        action="store_true",
        help="Skip pre-commit install.",
    )
    args = parser.parse_args()

    venv_path = REPO_ROOT / ".venv"
    try:
        py = ensure_venv(venv_path, args.skip_venv)
        ensure_profiles()
        if not args.no_pre_commit:
            optional_pre_commit(py)
    except subprocess.CalledProcessError as e:
        return e.returncode
    print("\nDone. Next:")
    print("  1. Set SNOW_ACCOUNT, SNOW_USER, SNOW_USER_PASSWORD (and optional SNOWFLAKE_*).")
    print("  2. From repo root:  dbt debug   then   dbt seed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
