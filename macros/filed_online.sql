{#
    This macro returns the description of the filed_online 
#}

{% macro file_status(filed_online) -%}

    case {{ dbt.safe_cast("filed_online", api.Column.translate_type("string")) }}  
        when 'true' then 'Filed Online'
        else 'Filed by SFPD'
    end

{%- endmacro %}