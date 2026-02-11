-- This model creates a staging view for the 'beds_h1' source table.
-- We are using a hardcoded, fully-quoted path to ensure dbt connects correctly.

WITH source_data AS (

    -- This hardcoded path directly references your case-sensitive table name.
    SELECT * FROM "HOSPITAL_DATA_DB"."HOSPITAL_BRONZE"."beds_H1"

),

cleaned_and_renamed AS (

    -- This CTE renames all columns to lowercase and sets the correct data types.
    SELECT
        "BED_ID" AS bed_id,
        "ROOM_ID" AS room_id,
        "STATUS" AS status,
        -- The patient_id can be null if the bed is available, so we keep it as is.
        "PATIENT_ID" AS patient_id,
        -- The date columns can be null, so we safely cast them.
        "OCCUPIED_FROM"::DATE AS occupied_from,
        "OCCUPIED_TILL"::DATE AS occupied_till,
        "LOADED_AT_UTC"::TIMESTAMP_TZ AS loaded_at_utc
    FROM source_data

),

deduplicated AS (
    SELECT
        *,
        -- This window function finds duplicate records for each bed.
        ROW_NUMBER() OVER(
            PARTITION BY
                bed_id
            -- If duplicates exist, this prioritizes keeping the most recently loaded one.
            ORDER BY loaded_at_utc DESC
        ) as rn
    FROM cleaned_and_renamed
)

-- The final SELECT statement retrieves all columns, excluding the temporary row number,
-- and filters to keep only the most recent unique record for each bed.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
