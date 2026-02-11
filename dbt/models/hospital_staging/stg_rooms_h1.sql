-- This model creates a staging view for the 'rooms_h1' source table.
-- It standardizes all names, handles data types, and deduplicates records.
-- We are using a hardcoded, fully-quoted path to ensure dbt connects correctly.

WITH source_data AS (

    -- This hardcoded path directly references your case-sensitive table name.
    SELECT * FROM "HOSPITAL_DATA_DB"."HOSPITAL_BRONZE"."rooms_H1"

),

cleaned_and_renamed AS (

    -- This CTE renames all columns to lowercase and sets the correct data types.
    SELECT
        "ROOM_ID" AS room_id,
        "DEPARTMENT_ID" AS department_id,
        "ROOM_TYPE" AS room_type,
        "FLOOR"::NUMBER AS floor,
        "CAPACITY"::NUMBER AS capacity,
        "STATUS" AS status,
        "DAILY_CHARGE"::NUMBER(10, 2) AS daily_charge,
        -- THIS IS THE FIX: Using the exact column name, with spaces, wrapped in quotes.
        "AVG MONTLY MAINTENANCE COST"::NUMBER(10, 2) AS avg_monthly_maintenance_cost,
        "LOADED_AT_UTC"::TIMESTAMP_TZ AS loaded_at_utc
    FROM source_data

),

deduplicated AS (
    SELECT
        *,
        -- This window function finds duplicate records for each room.
        ROW_NUMBER() OVER(
            PARTITION BY
                room_id
            -- If duplicates exist, this prioritizes keeping the most recently loaded one.
            ORDER BY loaded_at_utc DESC
        ) as rn
    FROM cleaned_and_renamed
)

-- The final SELECT statement retrieves all columns, excluding the temporary row number,
-- and filters to keep only the most recent unique record for each room.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
