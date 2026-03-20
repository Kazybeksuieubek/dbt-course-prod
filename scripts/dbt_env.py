#!/usr/bin/env python3
"""
Run dbt after loading the repo root `.env` file into the process environment.

dbt Core does not read `.env` by itself; `profiles.yml` uses env_var(), which only
sees real environment variables. This wrapper loads `.env` then execs dbt.

Usage (from repo root):
  python scripts/dbt_env.py debug
  python scripts/dbt_env.py seed
"""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    env_file = root / ".env"
    if env_file.exists():
        from dotenv import load_dotenv

        load_dotenv(env_file, override=False)
    else:
        print("Warning: no .env found at", env_file, file=sys.stderr)

    if os.name == "nt":
        dbt_exe = root / ".venv" / "Scripts" / "dbt.exe"
        cmd = [str(dbt_exe)] if dbt_exe.is_file() else ["dbt"]
    else:
        dbt_bin = root / ".venv" / "bin" / "dbt"
        cmd = [str(dbt_bin)] if dbt_bin.is_file() else ["dbt"]

    return subprocess.call(cmd + sys.argv[1:], cwd=root)


if __name__ == "__main__":
    raise SystemExit(main())
