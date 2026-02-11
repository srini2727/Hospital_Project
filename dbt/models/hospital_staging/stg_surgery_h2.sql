-- This model creates a staging view for the 'surgery_h1' source table.
-- It corrects a column misalignment issue, standardizes column names, and deduplicates records.
-- We are using a hardcoded, fully-quoted path to ensure dbt connects correctly.

WITH source_data AS (

    -- This hardcoded path directly references your case-sensitive table name.
    SELECT * FROM "HOSPITAL_DATA_DB"."HOSPITAL_BRONZE"."surgery_H2"

),

cleaned_and_renamed AS (

    -- This CTE corrects the column shift and renames columns.
    -- The logic checks if the "FEES" column contains text to identify broken rows.
    SELECT
        "APPOINTMENT_ID" AS appointment_id,
        "PATIENT_ID" AS patient_id,
        "DOCTOR_ID" AS doctor_id,
        "APPOINTMENT_DATE"::DATE AS surgery_date,
        "APPOINTMENT_TIME"::TIME AS surgery_time,
        "STATUS" AS status,
        "REASON" AS reason,
        "NOTES" AS notes,

        -- For broken rows (where FEES is text), the real suggestion is in the FEES column.
        -- We will call this 'outcome' for surgeries.
        CASE
            WHEN TRY_TO_DECIMAL("FEES") IS NULL THEN "FEES"
            ELSE NULL -- There is no suggestion/outcome column for correct rows
        END AS outcome,

        -- For broken rows, the real fee is in the PAYMENT_METHOD column.
        CASE
            WHEN TRY_TO_DECIMAL("FEES") IS NULL THEN TRY_TO_DECIMAL("PAYMENT_METHOD")
            ELSE TRY_TO_DECIMAL("FEES")
        END AS fees,

        -- For broken rows, the real payment method is in the DISCOUNT column.
        CASE
            WHEN TRY_TO_DECIMAL("FEES") IS NULL THEN "DISCOUNT"
            ELSE "PAYMENT_METHOD"
        END AS payment_method,

        -- For broken rows, the real discount is in the UNNAMED: 11 column.
        CASE
            WHEN TRY_TO_DECIMAL("FEES") IS NULL THEN TRY_TO_DECIMAL("UNNAMED: 11")
            ELSE "DISCOUNT"::NUMBER(10, 2)
        END AS discount,

        "LOADED_AT_UTC"::TIMESTAMP_TZ AS loaded_at_utc
    FROM source_data

),

deduplicated AS (
    SELECT
        *,
        -- This window function finds duplicate records for each surgery appointment.
        ROW_NUMBER() OVER(
            PARTITION BY
                appointment_id
            -- If duplicates exist, this prioritizes keeping the most recently loaded one.
            ORDER BY loaded_at_utc DESC
        ) as rn
    FROM cleaned_and_renamed
)

-- The final SELECT statement retrieves all columns, excluding the temporary row number,
-- and filters to keep only the most recent unique record for each surgery.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
