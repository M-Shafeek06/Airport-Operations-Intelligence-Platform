from pathlib import Path
import pandas as pd

from database import get_engine
from transform_fact_flights import transform_fact_flights
from validate_fact_flights import validate_fact_flights
from load_to_mysql import load_to_mysql

engine = get_engine()

try:
    with engine.connect():
        print("✅ Connected to MySQL!\n")
except Exception as e:
    print(e)
    raise SystemExit()


PROJECT_ROOT = Path(__file__).resolve().parent.parent

csv_path = (
    PROJECT_ROOT
    / "02_Raw_Data"
    / "Flights"
    / "On_Time_Reporting_Carrier_On_Time_Performance_(1987_present)_2024_1.csv"
)

print("Reading Flight Dataset...\n")

df_raw = pd.read_csv(
    csv_path,
    low_memory=False
)

print("✅ Dataset Loaded\n")

df_clean = df_raw.dropna(axis=1, how="all")

fact_df = transform_fact_flights(df_clean, engine)

validate_fact_flights(fact_df)

print("\n")
print("="*60)
print("FACT DATA")
print("="*60)

print(f"Rows : {fact_df.shape[0]:,}")
print(f"Columns : {fact_df.shape[1]}")

print(fact_df.head())
load_to_mysql(fact_df, engine)