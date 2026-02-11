-- This model combines hospital bill data from all hospital sources into one silver table.

WITH all_hospital_bills AS (

    SELECT * FROM {{ ref('stg_hospital_bills_h1') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_hospital_bills_h2') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_hospital_bills_h3') }}

)

SELECT
    *
FROM all_hospital_bills
