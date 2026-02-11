-- This model combines medical stock data from all hospital sources into one silver table.

WITH all_medical_stock AS (

    SELECT * FROM {{ ref('stg_medical_stock_h1') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_medical_stock_h2') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_medical_stock_h3') }}

)

SELECT
    *
FROM all_medical_stock
