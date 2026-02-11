-- This model creates a 'fact' table for appointments, ready for reporting.
-- It uses the corrected silver 'appointments' table and applies final formatting.

WITH appointments_silver AS (

    -- Select from the clean silver-layer appointments table
    SELECT * FROM {{ ref('appointments') }}

),

final AS (

    SELECT
        ROW_NUMBER() OVER(ORDER BY appointment_date, appointment_time) AS id,
        appointment_id,
        patient_id,
        doctor_id,

        -- THIS IS THE FIX: Using the explicit DAYNAME() function for robustness.
        -- This will now correctly output 'Sunday', 'Monday', etc.
        DAYNAME(appointment_date) || ', ' || TO_VARCHAR(appointment_date, 'MMMM DD, YYYY') AS appointment_date,

        TO_VARCHAR(appointment_time, 'HH12:MI AM') AS appointment_time,
        status,
        reason_for_visit AS reason,
        notes,
        suggestion AS suggest,
        diagnosis,
        fees,
        payment_method,
        discount,
        TO_VARCHAR(loaded_at_utc, 'MM/DD/YYYY HH:MI') AS upload_timestamp,

        TO_VARCHAR(appointment_time, 'HH:MI AM') || ' • ' || TO_VARCHAR(appointment_date, 'DD-Mon') AS "Appointment_Time_Date",

        CASE
            WHEN status = 'Completed' THEN 'https://i.ibb.co/T95RDdH/check.png'
            WHEN status = 'Scheduled' THEN 'https://i.ibb.co/3kC2sJc/calendar.png'
            ELSE NULL
        END AS "Status_icon"

    FROM appointments_silver
)

SELECT *
FROM final
