-- This model combines appointment data from all hospital sources into one silver table.
-- It now includes robust logic to fix misaligned/shifted columns from all three sources.

WITH appointments_h1 AS (

    SELECT
        appointment_id,
        patient_id,
        doctor_id,
        appointment_date,
        appointment_time,
        status,
        reason_for_visit,
        notes,
        -- If 'suggestion' contains a number, it's a broken row.
        -- In that case, the real fee is in the 'suggestion' column. Otherwise, it's in 'fees'.
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN TRY_TO_DECIMAL(suggestion)
            ELSE fees
        END AS fees,
        -- For broken rows, the payment_method is in the 'fees' column.
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN fees::VARCHAR
            ELSE payment_method
        END AS payment_method,
        -- For broken rows, the discount is in the 'payment_method' column.
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN TRY_TO_DECIMAL(payment_method)
            ELSE discount
        END AS discount,
        loaded_at_utc,
        -- For broken rows, the suggestion is NULL. Otherwise, use the real value.
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN NULL
            ELSE suggestion
        END AS suggestion,
        -- For broken rows, the diagnosis is in the 'discount' column.
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN discount::VARCHAR
            ELSE diagnosis
        END AS diagnosis
    FROM {{ ref('stg_appointments_h1') }}

),

appointments_h2 AS (

    -- Applying the same cleaning logic to the H2 source
    SELECT
        appointment_id,
        patient_id,
        doctor_id,
        appointment_date,
        appointment_time,
        status,
        reason_for_visit,
        notes,
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN TRY_TO_DECIMAL(suggestion)
            ELSE fees
        END AS fees,
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN fees::VARCHAR
            ELSE payment_method
        END AS payment_method,
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN TRY_TO_DECIMAL(payment_method)
            ELSE discount
        END AS discount,
        loaded_at_utc,
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN NULL
            ELSE suggestion
        END AS suggestion,
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN discount::VARCHAR
            ELSE diagnosis
        END AS diagnosis
    FROM {{ ref('stg_appointments_h2') }}

),

appointments_h3 AS (

    -- Applying the same cleaning logic to the H3 source
    SELECT
        appointment_id,
        patient_id,
        doctor_id,
        appointment_date,
        appointment_time,
        status,
        reason_for_visit,
        notes,
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN TRY_TO_DECIMAL(suggestion)
            ELSE fees
        END AS fees,
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN fees::VARCHAR
            ELSE payment_method
        END AS payment_method,
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN TRY_TO_DECIMAL(payment_method)
            ELSE discount
        END AS discount,
        loaded_at_utc,
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN NULL
            ELSE suggestion
        END AS suggestion,
        CASE
            WHEN TRY_TO_DECIMAL(suggestion) IS NOT NULL THEN discount::VARCHAR
            ELSE diagnosis
        END AS diagnosis
    FROM {{ ref('stg_appointments_h3') }}

),

all_appointments AS (

    SELECT * FROM appointments_h1

    UNION ALL

    SELECT * FROM appointments_h2

    UNION ALL

    SELECT * FROM appointments_h3
)

SELECT *
FROM all_appointments
