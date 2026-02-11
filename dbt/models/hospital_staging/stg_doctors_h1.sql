-- This model creates a staging view for the 'doctors_h1' source table.
-- It standardizes all names, handles data types, and deduplicates records.
-- We are using a hardcoded, fully-quoted path to ensure dbt connects correctly.

WITH source_data AS (

    -- This hardcoded path directly references your case-sensitive table name.
    SELECT * FROM "HOSPITAL_DATA_DB"."HOSPITAL_BRONZE"."doctors_H1"

),

cleaned_and_renamed AS (

    -- This CTE renames all columns to lowercase and sets the correct data types.
    SELECT
        "DOCTOR_ID" AS doctor_id,
        -- THIS IS THE FIX: The column name is "NAME", not the value in the first row.
        "NAME" AS doctor_name,
        "SPECIALIZATION" AS specialization,
        "DEPARTMENT" AS department,
        "SALARY"::NUMBER(10, 2) AS salary,
        "STATUS" AS status,
        "AVAILABILITY" AS availability,
        "JOINING_DATE"::DATE AS joining_date,
        "QUALIFICATION" AS qualification,
        "EXPERIENCE_YEARS"::NUMBER AS experience_years,
        "PHONE" AS phone,
        -- Handle potential 'null' strings in the email column
        CASE
            WHEN "EMAIL" = 'null' THEN NULL
            ELSE "EMAIL"
        END AS email,
        "IMG" AS image_url,
        "LOADED_AT_UTC"::TIMESTAMP_TZ AS loaded_at_utc
    FROM source_data

),

deduplicated AS (
    SELECT
        *,
        -- This window function finds duplicate records for each doctor.
        ROW_NUMBER() OVER(
            PARTITION BY
                doctor_id
            -- If duplicates exist, this prioritizes keeping the most recently loaded one.
            ORDER BY loaded_at_utc DESC
        ) as rn
    FROM cleaned_and_renamed
)

-- The final SELECT statement retrieves all columns, excluding the temporary row number,
-- and filters to keep only the most recent unique record for each doctor.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
