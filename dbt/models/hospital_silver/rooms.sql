-- This model combines room data from all hospital sources into one silver table.

WITH all_rooms AS (

    SELECT * FROM {{ ref('stg_rooms_h1') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_rooms_h2') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_rooms_h3') }}

)

SELECT
    *
FROM all_rooms
