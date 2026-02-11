-- This model combines patient test data from all hospital sources into one silver table.

WITH all_patient_tests AS (

    SELECT * FROM {{ ref('stg_patient_tests_h1') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_patient_tests_h2') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_patient_tests_h3') }}

)

SELECT
    *
FROM all_patient_tests
