from sodapy import Socrata
import pyarrow.parquet as pq
import pyarrow as pa
import os
import dlt
from dlt.destinations.impl.bigquery.bigquery_adapter import bigquery_adapter
import pandas as pd
# Set up authentication
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = 'service_acc.json' # YOUR SERVCE ACCOUNT HERE. Rename to `service_acc.json` to ensure reproducibility

# Unauthenticated client only works with public data sets. Note 'None'
# In place of application token, and no username or password:
client = Socrata("data.sfgov.org", None)
dataset_id = "wg3w-h783"
years = ['2018', '2019', '2020', '2021', '2022', '2023', '2024']

pipeline = dlt.pipeline(
    pipeline_name="police_incidents", destination="bigquery", dataset_name="incidents"
    )

numrows = 0
data = []
for year in years:
    where_clause = f"incident_year = '{year}'"
    print(f" ** Now processing {where_clause}")
    generator = client.get_all(dataset_id, where=where_clause)
    for row in generator:
        data.append(row)
        numrows += 1
    print(f' ** Retrieved {numrows} rows in total with this iteration')

# Write to Goolge Cloud storage:
    # Convert list of dictionaries to a PyArrow Table
table = pa.Table.from_pylist(data)
    
# Define the GCS path to write the Parquet files to
bucket = 'YOUR BUCKET NAME HERE'
key = f'police_reports.parquet'
gcs_path = f'{bucket}/{key}'

fs = pa.fs.GcsFileSystem()    
pq.write_to_dataset(
    table,
    root_path=gcs_path, 
    partition_cols=['incident_year'],
    filesystem=fs
)

# Write to Google Big Query:
# Apply column cluster options
data = pd.DataFrame(data).to_dict(orient="records")
data = bigquery_adapter(
    data, cluster=["incident_year", "incident_category", "police_district"]
)
pipeline.run(
data=data,
write_disposition="merge", 
primary_key='row_id',
table_name="incident_table",
staging='filesystem'
)

print(" ** Done uploading to GCS and Bigquery")