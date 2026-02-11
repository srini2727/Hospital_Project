-- This model creates a 'fact' table for patient tests, ready for reporting.
-- It cleans up ID prefixes, standardizes the discount column, and adds formatted columns.

WITH patient_tests_silver AS (

    -- Select all data from the silver-layer patient_tests table
    SELECT * FROM {{ ref('patient_tests') }}

),

final AS (

    SELECT
        -- Create a unique ID for each row
        ROW_NUMBER() OVER(ORDER BY test_date, patient_id, test_id) AS id,

        -- Add 'H3-' prefix if no other prefix exists.
        CASE
            WHEN patient_test_id NOT LIKE 'H1-%' AND patient_test_id NOT LIKE 'H2-%' THEN 'H3-' || patient_test_id
            ELSE patient_test_id
        END AS patient_test_id,

        patient_id,
        
        -- Remove the 'H3-' prefix from test_id.
        REPLACE(test_id, 'H3-', '') AS test_id,

        doctor_id,
        
        -- Format the date columns to be human-readable
        DAYNAME(test_date) || ', ' || TO_VARCHAR(test_date, 'MMMM DD, YYYY') AS test_date,
        DAYNAME(result_date) || ', ' || TO_VARCHAR(result_date, 'MMMM DD, YYYY') AS result_date,
        
        status,
        result,
        notes,
        amount,
        payment_method,
        
        -- THIS IS THE FIX: Standardize NULL discounts to be 0.
        COALESCE(discount, 0) AS discount,

        -- Format the loaded_at_utc column to match the desired output
        TO_VARCHAR(loaded_at_utc, 'MM/DD/YYYY HH:MI') AS upload_timestamp
        
    FROM patient_tests_silver

)

SELECT *
FROM final
