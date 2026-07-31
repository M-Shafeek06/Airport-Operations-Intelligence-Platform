import pandas as pd
from sqlalchemy import text


def load_to_mysql(df: pd.DataFrame, engine):

    print("\n" + "=" * 60)
    print("LOADING DATA INTO MYSQL")
    print("=" * 60)

    try:

        # Clear existing data
        with engine.begin() as conn:
            conn.execute(text("TRUNCATE TABLE fact_flights"))

        print("Old records removed.")

        # Load data
        df.to_sql(
            name="fact_flights",
            con=engine,
            if_exists="append",
            index=False,
            chunksize=5000,
            method="multi"
        )

        print(f"Loaded {len(df):,} records successfully.")

        # Validate row count
        with engine.connect() as conn:

            result = conn.execute(
                text("SELECT COUNT(*) FROM fact_flights")
            )

            total_rows = result.scalar()

        print(f"MySQL Row Count : {total_rows:,}")

        if total_rows == len(df):
            print("ETL Load Validation PASSED")
        else:
            print("ETL Load Validation FAILED")

    except Exception as e:

        print("LOAD FAILED")
        print(e)