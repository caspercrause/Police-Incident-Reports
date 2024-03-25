{{ config(materialized="table",
cluster_by = ["year", "incident_category", "neighborhood", "supervisor_name"],
)
 }}

with
    reporting_data_clean as (select * from {{ ref("stg_incidents") }}),
    supervisors as (select *, from {{ ref("get_districts") }})

select
    reporting_data_clean.incident_id,
    reporting_data_clean.incident_number,
    reporting_data_clean.incident_datetime,
    reporting_data_clean.incident_date,
    reporting_data_clean.report_date,
    reporting_data_clean.incident_day_of_week,
    reporting_data_clean.incident_day_of_week_iso,
    reporting_data_clean.year,
    reporting_data_clean.incident_category,
    reporting_data_clean.incident_subcategory,
    reporting_data_clean.filing_status,
    reporting_data_clean.police_district,
    reporting_data_clean.report_type_description,
    reporting_data_clean.incident_description,
    reporting_data_clean.resolution,
    reporting_data_clean.neighborhood,
    r.supervisor_name,
    reporting_data_clean.coordinates
from reporting_data_clean
inner join
    supervisors as r on reporting_data_clean.supervisor_district = r.supervisor_district
