-- This model combines satisfaction score data from all hospital sources into one silver table.

WITH all_satisfaction_scores AS (

    -- This ensures the model names match the staging filenames exactly (all lowercase)
    SELECT * FROM {{ ref('stg_satisfaction_score_h1') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_satisfaction_score_h2') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_satisfaction_score_h3') }}

)

SELECT
    *
FROM all_satisfaction_scores
