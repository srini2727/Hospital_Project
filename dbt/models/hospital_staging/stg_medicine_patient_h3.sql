-- This model creates a staging view for the 'medicine_patient_h1' source table.
-- This table links patients to the medicines they were prescribed.
-- We are using a hardcoded, fully-quoted path to ensure dbt connects correctly.

WITH source_data AS (

    -- This hardcoded path directly references your case-sensitive table name.
    SELECT * FROM "HOSPITAL_DATA_DB"."HOSPITAL_BRONZE"."medicine_patient_H3"

),

cleaned_and_renamed AS (

    -- This CTE renames all columns to lowercase and sets the correct data types.
    SELECT
        "PATIENT_ID" AS patient_id,
        "MEDICINE_ID" AS medicine_id,
        "QTY"::NUMBER AS quantity,
        "DATE"::DATE AS prescription_date,
        "LOADED_AT_UTC"::TIMESTAMP_TZ AS loaded_at_utc
    FROM source_data

),

deduplicated AS (
    SELECT
        *,
        -- This window function finds duplicate records for the same medicine given
        -- to the same patient on the same day.
        ROW_NUMBER() OVER(
            PARTITION BY
                patient_id,
                medicine_id,
                prescription_date
            -- If duplicates exist, this prioritizes keeping the most recently loaded one.
            ORDER BY loaded_at_utc DESC
        ) as rn
    FROM cleaned_and_renamed
)

-- The final SELECT statement retrieves all columns, excluding the temporary row number,
-- and filters to keep only the most recent unique record for each event.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
