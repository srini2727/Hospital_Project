-- This model creates a staging view for the 'medical_stock_h1' source table.
-- It standardizes all names, handles data types, and deduplicates records.
-- We are using a hardcoded, fully-quoted path to ensure dbt connects correctly.

WITH source_data AS (

    -- This hardcoded path directly references your case-sensitive table name.
    SELECT * FROM "HOSPITAL_DATA_DB"."HOSPITAL_BRONZE"."medical_stock_H3"

),

cleaned_and_renamed AS (

    -- This CTE renames all columns to lowercase and sets the correct data types.
    SELECT
        "MEDICINE_ID" AS medicine_id,
        "NAME" AS medicine_name,
        "CATEGORY" AS category,
        "SUPPLIER_ID" AS supplier_id,
        "COST_PRICE"::NUMBER(10, 2) AS cost_price,
        "UNIT_PRICE"::NUMBER(10, 2) AS unit_price,
        "STOCK_QTY"::NUMBER AS stock_quantity,
        "EXPIRY_DATE"::DATE AS expiry_date,
        "MANUFACTURE_DATE"::DATE AS manufacture_date,
        "BATCH_NUMBER" AS batch_number,
        "REORDER_LEVEL"::NUMBER AS reorder_level,
        "LOADED_AT_UTC"::TIMESTAMP_TZ AS loaded_at_utc
    FROM source_data

),

deduplicated AS (
    SELECT
        *,
        -- This window function finds duplicate records for each medicine batch.
        ROW_NUMBER() OVER(
            PARTITION BY
                medicine_id,
                batch_number
            -- If duplicates exist, this prioritizes keeping the most recently loaded one.
            ORDER BY loaded_at_utc DESC
        ) as rn
    FROM cleaned_and_renamed
)

-- The final SELECT statement retrieves all columns, excluding the temporary row number,
-- and filters to keep only the most recent unique record for each medicine batch.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
