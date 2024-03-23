{{
    config(
        materialized='view'
    )
}}


with 

    report_data as (

    select *, row_number() over(partition by row_id, report_datetime) as rn
    from {{ source('staging', 'incident_table') }}
    where row_id is not null

    )
    select
        -- identifiers
        cast(row_id as integer) as row_id,
        cast(incident_id as integer) as incident_id,
        cast(incident_number as integer) as incident_number,

        -- timestamps
        cast(report_datetime as timestamp) as report_datetime,
        cast(incident_datetime as timestamp) as incident_datetime,
        -- dates
        DATE(incident_date) as incident_date,
        DATE(report_datetime) as report_date,
        {{ dbt_date.day_name("incident_date", short=false) }} as incident_day_of_week, -- imported package: https://github.com/calogica/dbt-date/tree/0.10.0/#day_of_weekdate-isoweektrue
        {{ dbt_date.day_of_week("incident_date") }} as incident_day_of_week_iso, -- imported package: https://github.com/calogica/dbt-date/tree/0.10.0/#day_of_weekdate-isoweektrue
        cast(incident_year as integer) as year,
        --incident info
        incident_category,
        {{file_status("filed_online")}} as filing_status,
        police_district,
        report_type_description,
        incident_subcategory,
        incident_description,
        resolution,
        intersection,
        analysis_neighborhood as neighborhood,
        cast(supervisor_district as integer) as supervisor_district,
        concat(cast(latitude as string), ', ', cast(longitude as string)) as coordinates
        from report_data
        where rn = 1
        order by report_datetime asc
    
    -- dbt build --select <model_name> --vars '{'is_test_run': 'false'}'
<<<<<<< HEAD
    {% if var('is_test_run', default=false) %}

    limit 100

    {% endif %}
=======
    {% if var('is_test_run', default=true) %}

    limit 100

    {% endif %}
>>>>>>> 6db06845488b355aa4f172e26671115a67a0b0a9
