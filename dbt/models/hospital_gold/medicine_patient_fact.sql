-- This model creates a 'fact' table for medicine prescriptions, ready for reporting.
-- It cleans the medicine_id prefix and adds formatted columns.

WITH medicine_patient_silver AS (

    -- Select all data from the silver-layer medicine_patient table
    SELECT * FROM {{ ref('medicine_patient') }}

),

final AS (

    SELECT
        -- Create a unique ID for each row
        ROW_NUMBER() OVER(ORDER BY prescription_date, patient_id, medicine_id) AS id,

        patient_id,
        
        -- THIS IS THE FIX: Removing the unwanted 'H3-' prefix from the medicine_id
        REPLACE(medicine_id, 'H3-', '') AS medicine_id,
        
        quantity AS qty,

        -- Format the date to be human-readable
        DAYNAME(prescription_date) || ', ' || TO_VARCHAR(prescription_date, 'MMMM DD, YYYY') AS date,

        -- Format the loaded_at_utc column to match the desired output
        TO_VARCHAR(loaded_at_utc, 'MM/DD/YYYY HH:MI') AS upload_timestamp
        
    FROM medicine_patient_silver

)

SELECT *
FROM final
