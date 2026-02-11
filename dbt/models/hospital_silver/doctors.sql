-- This model combines doctor data from all hospital sources into one silver table.

WITH all_doctors AS (

    SELECT * FROM {{ ref('stg_doctors_h1') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_doctors_h2') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_doctors_h3') }}

)

SELECT
    *
FROM all_doctors
