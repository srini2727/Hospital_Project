-- This model creates a staging view for the 'SUPPLIER_H1' source table.
-- It standardizes column names, cleans up a data quality issue with the state
-- column, and removes duplicate rows.

WITH source_data AS (

    -- Select all data from the SUPPLIER_H1 source table.
    SELECT * FROM {{ source('hospital_bronze', 'SUPPLIER_H1') }}

),

renamed AS (

    -- This CTE renames the columns to a consistent lowercase format.
    -- NOTE: We are intentionally using the "state.1" column and renaming it to "state"
    -- because the original "STATE" column contains incorrect data.
    SELECT
        "SUPPLIER_ID" AS supplier_id,
        "NAME" AS name,
        "CONTACT_PERSON" AS contact_person,
        "PHONE" AS phone,
        "EMAIL" AS email,
        "ADDRESS" AS address,
        "CITY" AS city,
        "state.1" AS state, -- Using the correct state column
        "PINCODE" AS pincode,
        "CONTRACT_START_DATE" AS contract_start_date

    FROM source_data

),

deduplicated AS (

    SELECT
        *,
        -- The ROW_NUMBER() window function assigns a unique integer to each row.
        -- We partition by all the columns to identify rows that are complete duplicates.
        ROW_NUMBER() OVER(
            PARTITION BY
                supplier_id,
                name,
                contact_person,
                phone,
                email,
                address,
                city,
                state,
                pincode,
                contract_start_date
            ORDER BY (SELECT NULL) -- Order doesn't matter for finding exact duplicates
        ) as rn
    FROM renamed
    -- You can add a filter here to remove rows with NULLs in critical columns.
    -- For example: WHERE supplier_id IS NOT NULL

)

-- The final SELECT statement retrieves all columns from the deduplicated set,
-- excluding the row number column 'rn', and ensures only unique rows are returned.
SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
