-- This model combines surgery data from all hospital sources into one silver table.
-- It explicitly selects and aligns columns to handle structural differences.

WITH surgery_h1 AS (

    SELECT
        appointment_id,
        patient_id,
        doctor_id,
        surgery_date,
        surgery_time,
        status,
        reason,
        notes,
        fees,
        payment_method,
        discount,
        outcome
    FROM {{ ref('stg_surgery_h1') }}

),

surgery_h2 AS (

    -- THIS IS THE FIX: Selecting from the correct column names that
    -- exist in the staging view (surgery_date, not appointment_date).
    SELECT
        appointment_id,
        patient_id,
        doctor_id,
        surgery_date,
        surgery_time,
        status,
        reason,
        notes,
        fees,
        payment_method,
        discount,
        NULL AS outcome -- Creating a null column to match the structure of h1
    FROM {{ ref('stg_surgery_h2') }}

),

surgery_h3 AS (

    -- Applying the same fix to the h3 source.
    SELECT
        appointment_id,
        patient_id,
        doctor_id,
        surgery_date,
        surgery_time,
        status,
        reason,
        notes,
        fees,
        payment_method,
        discount,
        NULL AS outcome -- Creating a null column to match the structure of h1
    FROM {{ ref('stg_surgery_h3') }}

),

all_surgery AS (

    SELECT * FROM surgery_h1

    UNION ALL

    SELECT * FROM surgery_h2

    UNION ALL

    SELECT * FROM surgery_h3
)

-- Selecting all records from the combined set.
SELECT *
FROM all_surgery
