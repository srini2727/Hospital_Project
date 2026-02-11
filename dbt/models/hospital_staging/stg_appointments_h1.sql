-- This model creates a staging view for the 'appointments_h1' source table.
-- NOTE: We are bypassing the dbt source() function and using a hardcoded,
-- fully-quoted path because the standard dbt configuration was not working.

WITH source_data AS (

    -- This hardcoded path is successfully connecting to your table.
    SELECT * FROM "HOSPITAL_DATA_DB"."HOSPITAL_BRONZE"."appointments_H1"

),

cleaned_and_renamed AS (

    -- This CTE renames all columns to lowercase and cleans up data quality issues.
    SELECT
        "APPOINTMENT_ID" AS appointment_id,
        "PATIENT_ID" AS patient_id,
        "DOCTOR_ID" AS doctor_id,
        "APPOINTMENT_DATE"::DATE AS appointment_date,
        "APPOINTMENT_TIME"::TIME AS appointment_time,
        "STATUS" AS status,
        -- This is the corrected column name.
        "REASON" AS reason_for_visit,
        "NOTES" AS notes,
        "SUGGEST" AS suggestion,
        CASE
            WHEN "FEES" = 'Pending' THEN NULL
            ELSE TRY_TO_DECIMAL("FEES", 10, 2)
        END AS fees,
        "PAYMENT_METHOD" AS payment_method,
        CASE
            WHEN "DISCOUNT" = 'null' THEN NULL
            ELSE TRY_TO_DECIMAL("DISCOUNT", 10, 2)
        END AS discount,
        "DIAGNOSIS" AS diagnosis,
        "LOADED_AT_UTC"::TIMESTAMP_TZ AS loaded_at_utc
    FROM source_data

),

deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER(
            PARTITION BY
                appointment_id,
                patient_id,
                doctor_id,
                appointment_date
            ORDER BY loaded_at_utc DESC
        ) as rn
    FROM cleaned_and_renamed
)

SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
