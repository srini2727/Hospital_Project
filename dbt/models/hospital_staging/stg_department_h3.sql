-- This model creates a staging view for the 'DEPARTMENT_H3' source table.
-- It adds the missing 'H3' prefix to the head_doctor_id and removes duplicate rows.
-- We are using a hardcoded, fully-quoted path that we know works correctly.

WITH source_data AS (

    -- Using the hardcoded path to prevent connection/naming errors.
    SELECT * FROM "HOSPITAL_DATA_DB"."HOSPITAL_BRONZE"."DEPARTMENT_H3"

),

renamed_and_cleaned AS (

    -- This CTE renames columns and applies the prefix correction.
    SELECT
        "DEPARTMENT_ID" AS department_id,
        "NAME" AS name,
        "FLOOR" AS floor,
        -- THIS IS THE FIX: The || operator concatenates strings, adding the 'H3-' prefix.
        'H3-' || "HEAD_DOCTOR_ID" AS head_doctor_id,
        "TOTAL_STAFF" AS total_staff,
        "PHONE_EXTENSION" AS phone_extension
    FROM source_data

),

deduplicated AS (

    SELECT
        *,
        -- The ROW_NUMBER() function finds exact duplicates across all columns.
        ROW_NUMBER() OVER(
            PARTITION BY
                department_id,
                name,
                floor,
                head_doctor_id, -- This will now partition by the corrected head_doctor_id
                total_staff,
                phone_extension
            ORDER BY (SELECT NULL) -- Order doesn't matter for exact duplicates
        ) as rn
    FROM renamed_and_cleaned
)

-- The final SELECT statement retrieves all columns from the deduplicated set,
-- excluding the row number column 'rn', and ensures only unique rows are returned.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
