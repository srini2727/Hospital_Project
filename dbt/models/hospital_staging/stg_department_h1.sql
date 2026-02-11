-- This model creates a staging view for the 'DEPARTMENT_H1' source table.
-- It standardizes column names to lowercase and removes duplicate rows.

WITH source_data AS (

    -- Select all data from the DEPARTMENT_H1 source table.
    -- The source is defined in your schema.yml file.
    SELECT * FROM {{ source('hospital_bronze', 'DEPARTMENT_H1') }}

),

renamed AS (

    -- This CTE renames the columns to a consistent lowercase format
    -- and ensures data types are correct. Double quotes are used to handle
    -- case-sensitivity in Snowflake.
    SELECT
        "DEPARTMENT_ID" AS department_id,
        "NAME" AS name,
        "FLOOR" AS floor,
        "HEAD_DOCTOR_ID" AS head_doctor_id,
        "TOTAL_STAFF" AS total_staff,
        "PHONE_EXTENSION" AS phone_extension

    FROM source_data

),

deduplicated AS (

    SELECT
        *,
        -- The ROW_NUMBER() window function assigns a unique integer to each row.
        -- We partition by all the columns to identify rows that are complete duplicates.
        ROW_NUMBER() OVER(
            PARTITION BY
                department_id,
                name,
                floor,
                head_doctor_id,
                total_staff,
                phone_extension
            ORDER BY (SELECT NULL) -- Order doesn't matter as we are looking for exact duplicates
        ) as rn
    FROM renamed
    -- You can add a filter here to remove rows with NULLs in critical columns.
    -- For example: WHERE department_id IS NOT NULL

)

-- The final SELECT statement retrieves all columns from the deduplicated set,
-- excluding the row number column 'rn', and ensures only unique rows are returned.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
