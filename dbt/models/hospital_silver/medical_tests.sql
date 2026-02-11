-- This model combines medical test data from all hospital sources into one silver table.
-- This serves as a simple union of the clean staging data.

WITH all_medical_tests AS (

    -- We use ref() to select from our clean staging views.
    -- The model names must be lowercase to match the filenames.
    SELECT * FROM {{ ref('stg_medical_tests_h1') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_medical_tests_h2') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_medical_tests_h3') }}

)

-- Selecting all records from the combined set.
SELECT *
FROM all_medical_tests
