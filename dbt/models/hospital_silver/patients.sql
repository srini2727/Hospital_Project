-- This model combines patient data from all hospital sources into one silver table.

WITH all_patients AS (

    SELECT * FROM {{ ref('stg_patients_h1') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_patients_h2') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_patients_h3') }}

)

SELECT
    *
FROM all_patients
