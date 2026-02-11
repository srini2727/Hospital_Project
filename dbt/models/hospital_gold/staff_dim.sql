-- This model creates a dimensional view for staff.
-- It currently passes through data directly from the clean, silver-layer staff table.
-- This view can be enriched with more calculated columns in the future as needed.

SELECT
    *
FROM {{ ref('staff') }}
