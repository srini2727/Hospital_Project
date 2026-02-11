-- This model combines bed data from all hospital sources into one silver table.

WITH all_beds AS (

    SELECT * FROM {{ ref('stg_beds_h1') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_beds_h2') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_beds_h3') }}

)

SELECT
    *
FROM all_beds
