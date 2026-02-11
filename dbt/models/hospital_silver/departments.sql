-- This model combines department data from all hospital sources into one silver table.
-- This serves as a simple union of the clean staging data, with further
-- deduplication and dimensional modeling reserved for the gold layer.

WITH all_departments AS (

    -- THIS IS THE FIX: The model names inside ref() must be lowercase
    -- to exactly match the filenames (e.g., stg_department_h1.sql).
    SELECT * FROM {{ ref('stg_department_h1') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_department_h2') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_department_h3') }}

)

-- Selecting all records from the combined set.
-- This model intentionally includes all records from all sources, without deduplication at this stage.
SELECT *
FROM all_departments
