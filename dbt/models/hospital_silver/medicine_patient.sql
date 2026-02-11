-- This model combines medicine-patient data from all hospital sources into one silver table.

WITH all_medicine_patient AS (

    SELECT * FROM {{ ref('stg_medicine_patient_h1') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_medicine_patient_h2') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_medicine_patient_h3') }}

)

SELECT
    *
FROM all_medicine_patient
