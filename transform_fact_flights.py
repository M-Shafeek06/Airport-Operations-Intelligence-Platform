import pandas as pd


def transform_fact_flights(df: pd.DataFrame, engine):

    business_columns = [

        "FlightDate",

        "Reporting_Airline",
        "IATA_CODE_Reporting_Airline",
        "Flight_Number_Reporting_Airline",
        "Tail_Number",

        "OriginAirportID",
        "Origin",

        "DestAirportID",
        "Dest",

        "CRSDepTime",
        "DepTime",

        "CRSArrTime",
        "ArrTime",

        "DepDelay",
        "DepDelayMinutes",
        "DepDel15",

        "ArrDelay",
        "ArrDelayMinutes",
        "ArrDel15",

        "TaxiOut",
        "TaxiIn",

        "WheelsOff",
        "WheelsOn",

        "CRSElapsedTime",
        "ActualElapsedTime",
        "AirTime",

        "Distance",

        "CarrierDelay",
        "WeatherDelay",
        "NASDelay",
        "SecurityDelay",
        "LateAircraftDelay",

        "Cancelled",
        "CancellationCode",
        "Diverted"
    ]

    fact_df = df[business_columns].copy()

    # ---------------------------------------
    # Date Key
    # ---------------------------------------

    fact_df["FlightDate"] = pd.to_datetime(fact_df["FlightDate"])

    fact_df["date_key"] = (
        fact_df["FlightDate"]
        .dt.strftime("%Y%m%d")
        .astype(int)
    )

    fact_df.drop(columns=["FlightDate"], inplace=True)

    # Move date_key to first position

    cols = ["date_key"] + [c for c in fact_df.columns if c != "date_key"]
    fact_df = fact_df[cols]

    # ---------------------------------------
    # Rename Columns
    # ---------------------------------------

    fact_df.rename(
        columns={
            "Reporting_Airline":"reporting_airline",
            "IATA_CODE_Reporting_Airline":"airline_iata",
            "Flight_Number_Reporting_Airline":"flight_number",
            "Tail_Number":"tail_number",
            "OriginAirportID":"origin_airport_id",
            "Origin":"origin",
            "DestAirportID":"dest_airport_id",
            "Dest":"dest",
            "CRSDepTime":"crs_dep_time",
            "DepTime":"dep_time",
            "CRSArrTime":"crs_arr_time",
            "ArrTime":"arr_time",
            "DepDelay":"dep_delay",
            "DepDelayMinutes":"dep_delay_minutes",
            "DepDel15":"dep_del15",
            "ArrDelay":"arr_delay",
            "ArrDelayMinutes":"arr_delay_minutes",
            "ArrDel15":"arr_del15",
            "TaxiOut":"taxi_out",
            "TaxiIn":"taxi_in",
            "WheelsOff":"wheels_off",
            "WheelsOn":"wheels_on",
            "CRSElapsedTime":"crs_elapsed_time",
            "ActualElapsedTime":"actual_elapsed_time",
            "AirTime":"air_time",
            "Distance":"distance",
            "CarrierDelay":"carrier_delay",
            "WeatherDelay":"weather_delay",
            "NASDelay":"nas_delay",
            "SecurityDelay":"security_delay",
            "LateAircraftDelay":"late_aircraft_delay",
            "Cancelled":"cancelled",
            "CancellationCode":"cancellation_code",
            "Diverted":"diverted",
        },
        inplace=True
    )

    # ---------------------------------------
    # Lookup Surrogate Keys
    # ---------------------------------------
    
    # Read Dimension Tables
    dim_airline = pd.read_sql(
        """
        SELECT airline_key, iata
        FROM dim_airline
        """,
        engine
    )
    
    dim_airport = pd.read_sql(
        """
        SELECT airport_key, iata
        FROM dim_airport
        """,
        engine
    )
    
    # -------------------------------
    # Airline Lookup
    # -------------------------------
    
    fact_df = fact_df.merge(
        dim_airline,
        how="left",
        left_on="airline_iata",
        right_on="iata"
    )
    
    fact_df.drop(columns=["iata"], inplace=True)
    
    # -------------------------------
    # Origin Airport Lookup
    # -------------------------------
    
    origin_lookup = dim_airport.rename(
    columns={
        "airport_key": "origin_airport_key",
        "iata": "origin_iata"
    }
    )
    
    fact_df = fact_df.merge(
        origin_lookup,
        how="left",
        left_on="origin",
        right_on="origin_iata"
    )
    
    fact_df.drop(
        columns=["origin_iata"],
        inplace=True
    )

    # -------------------------------
    # Destination Airport Lookup
    # -------------------------------
    
    dest_lookup = dim_airport.rename(
    columns={
        "airport_key": "destination_airport_key",
        "iata": "dest_iata"
    }
    )   
    
    fact_df = fact_df.merge(
        dest_lookup,
        how="left",
        left_on="dest",
        right_on="dest_iata"
    )
    
    fact_df.drop(
    columns=["dest_iata"],
    inplace=True
    )

    # ---------------------------------------
    # Fill Delay Values
    # ---------------------------------------

    delay_columns = [
        "carrier_delay",
        "weather_delay",
        "nas_delay",
        "security_delay",
        "late_aircraft_delay"
    ]

    fact_df[delay_columns] = fact_df[delay_columns].fillna(0)

    # ---------------------------------------
    # Fill Flags
    # ---------------------------------------

    flag_columns = [
        "cancelled",
        "diverted",
        "dep_del15",
        "arr_del15"
    ]

    for col in flag_columns:
        fact_df[col] = fact_df[col].fillna(0).astype(int)

    # ---------------------------------------
    # Numeric Columns
    # ---------------------------------------

    numeric_columns = [
        "dep_delay",
        "dep_delay_minutes",
        "arr_delay",
        "arr_delay_minutes",
        "taxi_out",
        "taxi_in",
        "crs_elapsed_time",
        "actual_elapsed_time",
        "air_time",
    ]

    fact_df[numeric_columns] = fact_df[numeric_columns].fillna(0)

    # ---------------------------------------
    # Convert Surrogate Keys
    # ---------------------------------------

    fact_df["airline_key"] = (
        fact_df["airline_key"]
        .fillna(0)
        .astype(int)
    )

    fact_df["origin_airport_key"] = (
        fact_df["origin_airport_key"]
        .fillna(0)
        .astype(int)
    )

    fact_df["destination_airport_key"] = (
        fact_df["destination_airport_key"]
        .fillna(0)
        .astype(int)
    )

    return fact_df