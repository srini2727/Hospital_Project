-- This model creates a staging view for the 'hospital_bills_h1' source table.
-- It standardizes all names, handles data types, and deduplicates records.
-- We are using a hardcoded, fully-quoted path to ensure dbt connects correctly.

WITH source_data AS (

    -- This hardcoded path directly references your case-sensitive table name.
    SELECT * FROM "HOSPITAL_DATA_DB"."HOSPITAL_BRONZE"."hospital_bills_H3"

),

cleaned_and_renamed AS (

    -- This CTE renames all columns to lowercase and sets the correct data types.
    SELECT
        "BILL_ID" AS bill_id,
        "PATIENT_ID" AS patient_id,
        "ADMISSION_DATE"::DATE AS admission_date,
        -- Safely handle potential nulls in the discharge_date column
        "DISCHARGE_DATE"::DATE AS discharge_date,
        "ROOM_CHARGES"::NUMBER(10, 2) AS room_charges,
        "SURGERY_CHARGES"::NUMBER(10, 2) AS surgery_charges,
        "MEDICINE_CHARGES"::NUMBER(10, 2) AS medicine_charges,
        "TEST_CHARGES"::NUMBER(10, 2) AS test_charges,
        "DOCTOR_FEES"::NUMBER(10, 2) AS doctor_fees,
        "OTHER_CHARGES"::NUMBER(10, 2) AS other_charges,
        "TOTAL_AMOUNT"::NUMBER(10, 2) AS total_amount,
        "DISCOUNT"::NUMBER(10, 2) AS discount,
        "PAID_AMOUNT"::NUMBER(10, 2) AS paid_amount,
        "PAYMENT_STATUS" AS payment_status,
        "PAYMENT_METHOD" AS payment_method,
        "LOADED_AT_UTC"::TIMESTAMP_TZ AS loaded_at_utc
    FROM source_data

),

deduplicated AS (
    SELECT
        *,
        -- This window function finds duplicate records for each bill.
        ROW_NUMBER() OVER(
            PARTITION BY
                bill_id
            -- If duplicates exist, this prioritizes keeping the most recently loaded one.
            ORDER BY loaded_at_utc DESC
        ) as rn
    FROM cleaned_and_renamed
)

-- The final SELECT statement retrieves all columns, excluding the temporary row number,
-- and filters to keep only the most recent unique record for each bill.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
