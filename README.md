# Police Department Incident Reports: 2018 to Present

This dataset includes incident reports that have been filed as of January 1, 2018. These reports are filed by officers or self-reported by members of the public using SFPD’s online reporting system. The reports are categorized into the following groups based on how the report was received and the type of incident. 

## Disclaimer: 

The San Francisco Police Department does not guarantee the accuracy, completeness, timeliness or correct sequencing of the information as the data is subject to change as modifications and updates are completed.

## How the dataset is created

Data is added to open data once incident reports have been reviewed and approved by a supervising Sergeant or Lieutenant. Incident reports may be removed from the dataset if in compliance with court orders to seal records or for administrative purposes such as active internal affair investigations and/or criminal investigations.

The pipeline code is located on a virtual private server that is scheduled to be powered on a limitied amount of time every day in order to save cost. The code is containerized with docker and all instructions required to run the code and the cron scheduler live inside of the `Dockerfile`

## Context
This is the final project for the DataTalks.Club Data Engineering Zoomcamp. It's a free, practical, 10-week long course about the main concepts in Data Engineering.

## Problem Statement
TODO


## Data
All communication with the API is done through HTTPS, and errors are communicated through HTTP response codes. The San Francisco Data API is powered by [Socrata](https://dev.socrata.com/)


They have python package available that is utiltlized in the code to easily work with JSON data

## Technologies
 - GitHub - repository to host source code
 - Docker - to containerize code and schedule script execution periodically with `cron`
 - python `3.10.0`
    - pandas, sodapy, dlt, google-cloud-bigquery-storage
- dbt core for data tranformation
- Google Cloud: Google Cloud storage, BigQuery, Compute engine (VM)

## Repo content
 - python script called `upload_to_storage.py` to upload historical data to google cloud storage
 - python script called `daily_pipeline.py` to retrieve daily new cases from the San Fransisco Data API
 - service account json file (this is not pushed to GitHub)
 - `.dlt` directory that contains a `secrets.toml` file to authorize sending data to `Google Cloud Storage` and `BigQuery` (this file is also not pushed to GitHub).
Please see [these](https://dlthub.com/docs/dlt-ecosystem/destinations/bigquery) instructions on how to fill out the `secrets.toml` file
 - cronfile - cronfile created that schedules the script called `daily_pipeline.py` and creates a log file after completion
 - `package_requirements.txt` file that contains all modules used by the scripts
 - `Dockerfile` that creates an image which will upload historical data to `Google Cloud Storage` and then schdule the `daily_pipeline.py` script to run daily and upsert new rows found

## Pipeline dynamics
 The pipeline is managed by the `dlt` package. It will upsert records generated by the `daily_pipeline.py` script. Every row in the database has a unique id called `row_id`. To upsert new rows the `dlt` package has a write disposition feature called `merge` which identifies rows by their `primary key` in my case the `row_id`, updates the existing rows found and appends the new rows by doing a staging step. `BigQuery` supports `gcs` as a file staging destination. `dlt` will upload files in the parquet format to gcs and ask `BigQuery` to copy their data directly into the database

 ## Partitioning and clustering
  I will be using clustering because the number of columns in this data set is large and the querying will frequently be aggregated against certain fields

  Since I will be making a lot of queries based on the `Year`, `Incident Category`, and `Police District` I have created a python code snippet to cluster on these particular fields

  ```
bigquery_adapter(
    data, cluster=["incident_year", "incident_category", "police_district"]
)
  ```
This means we will not know the upfront cost benefits of applying clustering to our data because there are no partitions. But since I will be aggregating the data based on multiple fields, clustering will be the better option where as with partitioning you generally filter on a single field.

## Architecture
Add IMAGE

## Dashboard
TODO

## To recreate
To recreate this you can either deploy it on a virtual machine, locally in a docker container or on GitHub Code Spaces

🚀        🚀        🚀

Prior to running this you will need to create a bucket in google big query storage and set up your `secrets.toml` file and you will need to have a service account and copy it into the current working directory. Rename it to `service_acc.json` to ensure reproducibility. You also need to give the name of that bucket you created in line `37` of `upload_to_storage.py`
1. Firstly you need to build a docker image. I called it `incidents`. Building this image takes around 10 - 15 minutes because of the `upload_to_storage.py` script that is executed by the `Dockerfile` so please be patient 🙂
```
docker build -t incidents .
```

2. Next you need to run a container. This container will schedule a script via `cron` to run daily. This daily pipeline adds new incident reports and updates existing records for the last two months. The reasoning behind this is that, occasionally, case details are entered incorrectly and is updated. To ensure that these changes are correctly captured in my pipeline I use `dlt` to upsert entries for the previous month until whatever the date of today is

```
docker run --name mycontainer --privileged -d incidents
```

These two commands will have started the pipelines and data should show up in `bigquery`.