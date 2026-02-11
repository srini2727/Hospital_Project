-- This model creates a 'fact' table for individual bill line items.
-- It uses the silver 'hospital_bills' table and "unpivots" the various
-- charge columns into a single, long-format table perfect for analysis.

WITH bills_silver AS (

    -- Select from the silver-layer hospital_bills table
    SELECT * FROM {{ ref('hospital_bills') }}

),

final AS (

    SELECT
        bill_id,
        patient_id,
        payment_status,
        payment_method,

        -- This CASE statement cleans up the unpivoted column names to be more readable.
        CASE
            WHEN charge_type = 'ROOM_CHARGES' THEN 'Room'
            WHEN charge_type = 'SURGERY_CHARGES' THEN 'Surgery'
            WHEN charge_type = 'MEDICINE_CHARGES' THEN 'Medicine'
            WHEN charge_type = 'TEST_CHARGES' THEN 'Test'
            WHEN charge_type = 'DOCTOR_FEES' THEN 'Doctor'
            WHEN charge_type = 'OTHER_CHARGES' THEN 'Other'
            WHEN charge_type = 'DISCOUNT' THEN 'Discount'
        END AS charge_type,

        value

    FROM bills_silver
    -- The UNPIVOT function transforms columns into rows.
    UNPIVOT(value FOR charge_type IN (
        room_charges,
        surgery_charges,
        medicine_charges,
        test_charges,
        doctor_fees,
        other_charges,
        discount
    ))

)

SELECT *
FROM final
-- We can filter out rows where the value is zero, as they don't represent a charge.
WHERE value != 0
