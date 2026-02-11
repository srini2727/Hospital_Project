-- This model creates a staging view for the 'patient_tests_h1' source table.
-- It standardizes all names, handles data types, and deduplicates records.
-- We are using a hardcoded, fully-quoted path to ensure dbt connects correctly.

WITH source_data AS (

    -- This hardcoded path directly references your case-sensitive table name.
    SELECT * FROM "HOSPITAL_DATA_DB"."HOSPITAL_BRONZE"."patient_tests_H1"

),

cleaned_and_renamed AS (

    -- This CTE renames all columns to lowercase and sets the correct data types.
    SELECT
        "PATIENT_TEST_ID" AS patient_test_id,
        "PATIENT_ID" AS patient_id,
        "TEST_ID" AS test_id,
        "DOCTOR_ID" AS doctor_id,
        "TEST_DATE"::DATE AS test_date,
        "RESULT_DATE"::DATE AS result_date,
        "STATUS" AS status,
        "RESULT" AS result,
        "NOTES" AS notes,
        "AMOUNT"::NUMBER(10, 2) AS amount,
        "PAYMENT_METHOD" AS payment_method,
        -- Safely handle potential 'null' strings in the discount column
        CASE
            WHEN "DISCOUNT" = 'null' THEN NULL
            ELSE "DISCOUNT"::NUMBER(10, 2)
        END AS discount,
        "LOADED_AT_UTC"::TIMESTAMP_TZ AS loaded_at_utc
    FROM source_data

),

deduplicated AS (
    SELECT
        *,
        -- This window function finds duplicate records for each patient test.
        ROW_NUMBER() OVER(
            PARTITION BY
                patient_test_id
            -- If duplicates exist, this prioritizes keeping the most recently loaded one.
            ORDER BY loaded_at_utc DESC
        ) as rn
    FROM cleaned_and_renamed
)

-- The final SELECT statement retrieves all columns, excluding the temporary row number,
-- and filters to keep only the most recent unique record for each patient test.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
