-- This model creates an aggregated view for bed information.
-- It counts the number of beds, grouping them by room, type, and status.

WITH beds AS (
    SELECT * FROM {{ ref('beds') }}
),

rooms AS (
    SELECT * FROM {{ ref('rooms') }}
),

final AS (
    SELECT
        -- The columns we are grouping by
        r.room_id,
        r.room_type,
        b.status,
        -- The aggregated column: the count of beds in each group
        COUNT(b.bed_id) AS bed_count

    FROM beds AS b
    LEFT JOIN rooms AS r ON b.room_id = r.room_id
    GROUP BY
        r.room_id,
        r.room_type,
        b.status
)

SELECT *
FROM final
