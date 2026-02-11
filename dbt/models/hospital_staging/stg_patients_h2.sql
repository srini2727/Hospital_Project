-- This model creates a staging view for the 'patients_h1' source table.
-- It standardizes all names, handles data types, and deduplicates records.
-- We are using a hardcoded, fully-quoted path to ensure dbt connects correctly.

WITH source_data AS (

    -- This hardcoded path directly references your case-sensitive table name.
    SELECT * FROM "HOSPITAL_DATA_DB"."HOSPITAL_BRONZE"."patients_H2"

),

cleaned_and_renamed AS (

    -- This CTE renames all columns to lowercase and sets the correct data types.
    SELECT
        "PATIENT_ID" AS patient_id,
        "NAME" AS patient_name,
        "AGE"::NUMBER AS age,
        "GENDER" AS gender,
        "WEIGHT"::NUMBER AS weight,
        "BLOOD_GROUP" AS blood_group,
        "ADDRESS" AS address,
        "STATE" AS state,
        "PHONE" AS phone,
        "EMAIL" AS email,
        "ADMISSION_DATE"::DATE AS admission_date,
        -- Safely handle nulls in the discharge_date column
        "DISCHARGE_DATE"::DATE AS discharge_date,
        "STATUS" AS admission_status,
        "IMG" AS image_url,
        "LOADED_AT_UTC"::TIMESTAMP_TZ AS loaded_at_utc
    FROM source_data

),

deduplicated AS (
    SELECT
        *,
        -- This window function finds duplicate records for each patient.
        ROW_NUMBER() OVER(
            PARTITION BY
                patient_id
            -- If duplicates exist, this prioritizes keeping the most recently loaded one.
            ORDER BY loaded_at_utc DESC
        ) as rn
    FROM cleaned_and_renamed
)

-- The final SELECT statement retrieves all columns, excluding the temporary row number,
-- and filters to keep only the most recent unique record for each patient.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
