import os
import sys
import glob
import pandas as pd
import snowflake.connector
from dotenv import load_dotenv

# Load .env from project root (parent of scripts/)
load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

# Snowflake connection parameters
# -------------------------------
ACCOUNT = os.getenv('SNOW_ACCOUNT')
USER = os.getenv('SNOW_USER')
PASSWORD = os.getenv('SNOW_USER_PASSWORD')

if not all([ACCOUNT, USER, PASSWORD]):
    missing = [k for k, v in [('SNOW_ACCOUNT', ACCOUNT), ('SNOW_USER', USER), ('SNOW_USER_PASSWORD', PASSWORD)] if not v]
    print(f"Missing Snowflake credentials: {', '.join(missing)}")
    print("Copy .env.example to .env in the project root and set SNOW_ACCOUNT, SNOW_USER, SNOW_USER_PASSWORD.")
    sys.exit(1)

WAREHOUSE = "COMPUTE_WH"
DATABASE = "dbt_project"
SCHEMA = "raw"
# -------------------------------


def connect_to_snowflake(account, user, password, warehouse, database, schema):
    """Establish connection to Snowflake."""
    try:
        conn = snowflake.connector.connect(
            account=account,
            user=user,
            password=password,
            warehouse=warehouse,
            database=database,
            schema=schema
        )
        print(f"Connected to Snowflake: {database}.{schema}")
        return conn
    except Exception as e:
        print(f"Error connecting to Snowflake: {str(e)}")
        sys.exit(1)

def create_database_and_schema(conn, database, schema):
    """Create database and schema if they don't exist."""
    try:
        cursor = conn.cursor()
        cursor.execute(f"CREATE DATABASE IF NOT EXISTS {database};")
        print(f"Database {database} created or already exists.")

        cursor.execute(f"CREATE SCHEMA IF NOT EXISTS {database}.{schema};")
        print(f"Schema {schema} created or already exists in database {database}.")

        cursor.execute(f"USE DATABASE {database};")
        cursor.execute(f"USE SCHEMA {schema};")

        cursor.close()
        return True
    except Exception as e:
        print(f"Error creating database or schema: {str(e)}")
        return False

def get_column_definitions(csv_file):
    """Read the first CSV file to determine column definitions."""
    try:
        df = pd.read_csv(csv_file, nrows=0)
        columns = []

        # Infer data types from column names and make best guess
        for col in df.columns:
            columns.append(f'{col} VARCHAR(500)')

        return columns
    except Exception as e:
        print(f"Error analyzing CSV file {csv_file}: {str(e)}")
        return None

def create_csv_file_format(conn, file_format_name):
    """Create a CSV file format if it doesn't exist."""
    try:
        cursor = conn.cursor()
        cursor.execute(f"""
            CREATE OR ALTER FILE FORMAT {file_format_name}
              TYPE = 'CSV'
              FIELD_DELIMITER = ','
              SKIP_HEADER = 1
              FIELD_OPTIONALLY_ENCLOSED_BY = '"'
              NULL_IF = ('')
              EMPTY_FIELD_AS_NULL = TRUE
              TIMESTAMP_FORMAT = 'AUTO'
            ;"""
        )
        print(f"File format {file_format_name} created or already exists.")
        cursor.close()
        return True
    except Exception as e:
        print(f"Error creating file format: {str(e)}")
        return False

def create_stage(conn, stage_name, file_format_name):
    """Create a stage if it doesn't exist."""
    try:
        cursor = conn.cursor()
        cursor.execute(f"CREATE OR ALTER STAGE {stage_name} FILE_FORMAT = (FORMAT_NAME = {file_format_name});")
        print(f"Stage {stage_name} created or already exists.")
        cursor.close()
        return True
    except Exception as e:
        print(f"Error creating stage: {str(e)}")
        return False

def create_table(conn, table_name, column_defs):
    """Create a table if it doesn't exist with the specified columns."""
    if not column_defs:
        return False

    try:
        cursor = conn.cursor()
        columns_sql = ", ".join(column_defs)
        create_table_sql = f"CREATE TABLE IF NOT EXISTS {table_name} ({columns_sql});"
        cursor.execute(create_table_sql)
        print(f"Table {table_name} created or already exists.")
        cursor.close()
        return True
    except Exception as e:
        print(f"Error creating table {table_name}: {str(e)}")
        return False

def create_pipe(conn, pipe_name, table_name, stage_path, format_name):
    """Create a Snowflake pipe to load data from stage to table."""
    try:
        cursor = conn.cursor()

        # Check if pipe already exists
        cursor.execute(f"SHOW PIPES LIKE '{pipe_name}'")
        pipe_exists = cursor.fetchone() is not None

        if not pipe_exists:
            create_pipe_sql = f"""
            CREATE PIPE {pipe_name} AS
            COPY INTO {table_name}
            FROM @{stage_path}
            FILE_FORMAT = (FORMAT_NAME = {format_name})
            ON_ERROR = 'CONTINUE';
            """
            cursor.execute(create_pipe_sql)
            print(f"Pipe {pipe_name} created.")
        else:
            print(f"Pipe {pipe_name} already exists.")

        cursor.close()
        return True
    except Exception as e:
        print(f"Error creating pipe {pipe_name}: {str(e)}")
        return False

def upload_files_to_stage(conn, stage_path, local_folder_path):
    """Upload all CSV files from local folder to stage."""
    try:
        cursor = conn.cursor()
        csv_files = glob.glob(os.path.join(local_folder_path, "*.csv"))

        if not csv_files:
            print(f"No CSV files found in {local_folder_path}")
            return False

        for csv_file in csv_files:
            file_name = os.path.basename(csv_file)
            put_command = f"PUT file://{csv_file.replace(os.sep, '/')} @{stage_path} AUTO_COMPRESS=TRUE OVERWRITE=TRUE;"
            print(f"Uploading {file_name} to {stage_path}...")
            cursor.execute(put_command)

        print(f"All files uploaded to {stage_path}")
        cursor.close()
        return True
    except Exception as e:
        print(f"Error uploading files to stage {stage_path}: {str(e)}")
        return False

def refresh_pipes(conn, schema):
    try:
        cursor = conn.cursor()
        cursor.execute(f"USE SCHEMA {schema}")
        cursor.execute("SHOW PIPES")
        pipes = cursor.fetchall()
        for pipe in pipes:
            pipe_name = pipe[1]
            cursor.execute(f"ALTER PIPE {pipe_name} REFRESH")
            print(f"Pipe {pipe_name} refreshed.")
        cursor.close()
        return True
    except Exception as e:
        print(f"Error refreshing pipes: {str(e)}")
        return False

def process_folder(root_folder, snowflake_conn, stage_name):
    """Process all subfolders in the input folder."""
    if not os.path.isdir(root_folder):
        print(f"Error: {root_folder} is not a valid directory")
        return

    if not create_csv_file_format(snowflake_conn, "CSV_FORMAT"):
        return

    if not create_stage(snowflake_conn, stage_name, "CSV_FORMAT"):
        return

    # Process each subfolder
    for subfolder_name in os.listdir(root_folder):
        subfolder_path = os.path.join(root_folder, subfolder_name)

        if not os.path.isdir(subfolder_path):
            continue

        # Create subfolder in stage
        stage_subfolder = f"{stage_name}/{subfolder_name}"

        # Get first CSV to determine table structure
        csv_files = glob.glob(os.path.join(subfolder_path, "*.csv"))
        if not csv_files:
            print(f"No CSV files found in {subfolder_path}, skipping...")
            continue

        # Create table
        table_name = subfolder_name.upper()
        column_defs = get_column_definitions(csv_files[0])
        if not create_table(snowflake_conn, table_name, column_defs):
            continue

        # Create pipe
        pipe_name = f"{table_name}_PIPE"
        if not create_pipe(snowflake_conn, pipe_name, table_name, stage_subfolder, "CSV_FORMAT"):
            continue

        # Upload files
        if not upload_files_to_stage(snowflake_conn, stage_subfolder, subfolder_path):
            continue

        print(f"Processed subfolder: {subfolder_name}")

def main():
    """Main function to parse arguments and execute the workflow."""
    if len(sys.argv) < 2:
        print("Usage: python script.py <folder_path>")
        sys.exit(1)

    folder_path = sys.argv[1]

    # Connect to Snowflake
    conn = connect_to_snowflake(ACCOUNT, USER, PASSWORD, WAREHOUSE, DATABASE, SCHEMA)

        # Create database and schema if needed
    if not create_database_and_schema(conn, DATABASE, SCHEMA):
        conn.close()
        sys.exit(1)

    # Process folder
    stage_name = "CSV_STAGE"
    process_folder(folder_path, conn, stage_name)

    refresh_pipes(conn, SCHEMA)

    # Close connection
    conn.close()
    print("Process completed.")

if __name__ == "__main__":
    main()
