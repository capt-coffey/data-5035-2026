import pandas as pd
from snowflake.snowpark.context import get_active_session

session = get_active_session()

query = """
    SELECT
        rs.segment_id,
        rs.corridor,
        rs.geog,
        tc.aadt,
        tc.ev_share,
        tc.truck_share,
        wr.weather_risk_score
    FROM data5035.spring26.road_segments rs
    JOIN data5035.spring26.traffic_counts tc ON rs.segment_id = tc.segment_id
    JOIN data5035.spring26.weather_risk   wr ON rs.segment_id = wr.segment_id
"""

df = session.sql(query).to_pandas()

print(df.shape)
print(df.head())