-- This model combines staff data from all hospital sources into one silver table.

WITH all_staff AS (

    SELECT * FROM {{ ref('stg_staff_h1') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_staff_h2') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_staff_h3') }}

)

SELECT
    *
FROM all_staff
