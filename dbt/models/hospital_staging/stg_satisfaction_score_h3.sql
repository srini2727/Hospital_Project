-- This model creates a staging view for the 'satisfaction_score_h1' source table.
-- It standardizes all names, handles data types, and deduplicates records.
-- We are using a hardcoded, fully-quoted path to ensure dbt connects correctly.

WITH source_data AS (

    -- This hardcoded path directly references your case-sensitive table name.
    SELECT * FROM "HOSPITAL_DATA_DB"."HOSPITAL_BRONZE"."satisfaction_score_H3"

),

cleaned_and_renamed AS (

    -- This CTE renames all columns to lowercase and sets the correct data types.
    SELECT
        "SATISFACTION_ID" AS satisfaction_id,
        "PATIENT_ID" AS patient_id,
        "DOCTOR_ID" AS doctor_id,
        "RATING"::NUMBER AS rating,
        "FEEDBACK" AS feedback,
        "DATE"::DATE AS survey_date,
        "DEPARTMENT" AS department,
        "LOADED_AT_UTC"::TIMESTAMP_TZ AS loaded_at_utc
    FROM source_data

),

deduplicated AS (
    SELECT
        *,
        -- This window function finds duplicate records for each satisfaction survey.
        ROW_NUMBER() OVER(
            PARTITION BY
                satisfaction_id
            -- If duplicates exist, this prioritizes keeping the most recently loaded one.
            ORDER BY loaded_at_utc DESC
        ) as rn
    FROM cleaned_and_renamed
)

-- The final SELECT statement retrieves all columns, excluding the temporary row number,
-- and filters to keep only the most recent unique record for each survey.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
