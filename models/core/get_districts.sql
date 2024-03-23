{{
    config(
        materialized='table'
    )
}}

select 
    sup_name as supervisor_name,
    cast(sup_dist as integer) as supervisor_district

from {{ ref('supervisor_districts') }}