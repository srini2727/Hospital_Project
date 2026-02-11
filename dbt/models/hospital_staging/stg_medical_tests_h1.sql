-- This model creates a staging view for the 'MEDICAL_TESTS_H1' source table.
-- It standardizes column names to lowercase and removes duplicate rows.

WITH source_data AS (

    -- Select all data from the MEDICAL_TESTS_H1 source table.
    SELECT * FROM {{ source('hospital_bronze', 'MEDICAL_TESTS_H1') }}

),

renamed AS (

    -- This CTE renames the columns to a consistent lowercase format.
    -- Double quotes are used to handle case-sensitivity in Snowflake.
    SELECT
        "TEST_ID" AS test_id,
        "TEST_NAME" AS test_name,
        "CATEGORY" AS category,
        "DEPARTMENT_ID" AS department_id,
        "COST" AS cost,
        "DURATION_MINUTES" AS duration_minutes,
        "FASTING_REQUIRED" AS fasting_required

    FROM source_data

),

deduplicated AS (

    SELECT
        *,
        -- The ROW_NUMBER() window function assigns a unique integer to each row.
        -- We partition by all the columns to identify rows that are complete duplicates.
        ROW_NUMBER() OVER(
            PARTITION BY
                test_id,
                test_name,
                category,
                department_id,
                cost,
                duration_minutes,
                fasting_required
            ORDER BY (SELECT NULL) -- Order doesn't matter for finding exact duplicates
        ) as rn
    FROM renamed
    -- You can add a filter here to remove rows with NULLs in critical columns.
    -- For example: WHERE test_id IS NOT NULL

)

-- The final SELECT statement retrieves all columns from the deduplicated set,
-- excluding the row number column 'rn', and ensures only unique rows are returned.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
