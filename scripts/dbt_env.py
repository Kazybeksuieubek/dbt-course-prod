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

    tool = sys.argv[1] if sys.argv[1:] else "dbt"
    args = sys.argv[2:]

    if tool == "mf":
        os.environ.setdefault("DBT_PROFILES_DIR", str(Path.home() / ".dbt"))
        os.environ["PYTHONUTF8"] = "1"
        os.environ["PYTHONIOENCODING"] = "utf-8"
        if os.name == "nt":
            exe = root / ".venv-mf" / "Scripts" / "mf.exe"
            cmd = [str(exe)] if exe.is_file() else ["mf"]
        else:
            exe = root / ".venv-mf" / "bin" / "mf"
            cmd = [str(exe)] if exe.is_file() else ["mf"]
    else:
        args = sys.argv[1:]
        if os.name == "nt":
            exe = root / ".venv" / "Scripts" / "dbt.exe"
            cmd = [str(exe)] if exe.is_file() else ["dbt"]
        else:
            exe = root / ".venv" / "bin" / "dbt"
            cmd = [str(exe)] if exe.is_file() else ["dbt"]

    return subprocess.call(cmd + args, cwd=root)


if __name__ == "__main__":
    raise SystemExit(main())
