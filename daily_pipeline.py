from sodapy import Socrata
import dlt
from dlt.destinations.impl.bigquery.bigquery_adapter import bigquery_adapter
import pandas as pd
from datetime import datetime as dt
from dateutil.relativedelta import relativedelta

# Create a string based on the date of today and floor it to the beginning of the previous month
CurrentMonth = (dt.now() - relativedelta(months=1)).strftime('%Y-%m-01T00:01:00.000')

# Unauthenticated client only works with public data sets. Note 'None'
# in place of application token, and no username or password:
client = Socrata("data.sfgov.org", None)
dataset_id = "wg3w-h783"

# Filter data set for all records in the current month
where_clause = f"report_datetime > '{CurrentMonth}'"
generator = client.get_all(dataset_id, where = where_clause)

# Create a string for log output:
Now_str = dt.now().strftime('%a, %b %d, %Y at %H:%M:%S')

# Define dlt pipeline:
pipeline = dlt.pipeline(
    pipeline_name="police_incidents", destination="bigquery", dataset_name="incidents", progress='enlighten'
    )

data = []
script_failure = None

try:
    for row in generator:
        data.append(row)
    script_failure = False
    print(f' ** Found {len(data)} rows.')
except:
    print(f" ** Something went wrong with data retrieval step on {Now_str}")
    script_failure = True

finally:
    if script_failure==False:
        data = pd.DataFrame(data).to_dict(orient='records')
        # Apply column cluster options
        data = bigquery_adapter(
        data, cluster=["incident_year", "incident_category", "police_district"]
        )

        # Perform incremental load. Upsert. Update existing record values found and append new records
        pipeline.run(
        data=data,
        write_disposition="merge", 
        primary_key='row_id',
        table_name="incident_table",
        staging='filesystem'
        )

        print(f' ** Finished uploading on {Now_str}')
    else:
        print(f' ** No new records could be uploaded on {Now_str}')