import pandas as pd


def validate_fact_flights(df: pd.DataFrame):

    print("\n" + "="*60)
    print("VALIDATION REPORT")
    print("="*60)

    print(f"Rows : {len(df):,}")

    print(f"Duplicate Rows : {df.duplicated().sum()}")

    print(f"Missing date_key : {df['date_key'].isna().sum()}")

    print(f"Missing airline_key : {(df['airline_key'] == 0).sum()}")

    print(f"Missing origin_airport_key : {(df['origin_airport_key'] == 0).sum()}")

    print(f"Missing destination_airport_key : {(df['destination_airport_key'] == 0).sum()}")

    print(f"Negative Distance : {(df['distance']<0).sum()}")

    print(f"Negative Air Time : {(df['air_time']<0).sum()}")

    print("="*60)
    print("Validation Completed")
    print("="*60)