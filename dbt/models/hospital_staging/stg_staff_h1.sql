-- This model creates a staging view for the 'staff_h1' source table.
-- It cleans up address data that was split across multiple columns,
-- standardizes all names, and deduplicates records.
-- We are using a hardcoded, fully-quoted path to ensure dbt connects correctly.

WITH source_data AS (

    -- This hardcoded path directly references your case-sensitive table name.
    SELECT * FROM "HOSPITAL_DATA_DB"."HOSPITAL_BRONZE"."staff_H1"

),

cleaned_and_renamed AS (

    -- This CTE renames all columns to lowercase and sets the correct data types.
    SELECT
        "STAFF_ID" AS staff_id,
        "NAME" AS staff_name,
        "DEPARTMENT_ID" AS department_id,
        "ROLE" AS role,
        "SALARY"::NUMBER(10, 2) AS salary,
        "JOINING_DATE"::DATE AS joining_date,
        "SHIFT" AS shift,
        "PHONE" AS phone,
        "EMAIL" AS email,
        -- We combine the three separate address columns into one full address.
        -- The || operator concatenates strings.
        "ADDRESS" || ', ' || "UNNAMED: 10" || ', ' || "UNNAMED: 11" AS address,
        "LOADED_AT_UTC"::TIMESTAMP_TZ AS loaded_at_utc
    FROM source_data

),

deduplicated AS (
    SELECT
        *,
        -- This window function finds duplicate records for each staff member.
        ROW_NUMBER() OVER(
            PARTITION BY
                staff_id
            -- If duplicates exist, this prioritizes keeping the most recently loaded one.
            ORDER BY loaded_at_utc DESC
        ) as rn
    FROM cleaned_and_renamed
)

-- The final SELECT statement retrieves all columns, excluding the temporary row number,
-- and filters to keep only the most recent unique record for each staff member.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
