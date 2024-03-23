{{
    config(
        materialized='table'
    )
}}

select 
    sup_name as supervisor_name,
    sup_dist as supervisor_district

from {{ ref('supervisor_districts') }}