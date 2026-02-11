{#
    This macro defines a generic test that checks if the row count of a child model
    matches the sum of row counts from its parent models.
#}

{% macro test_row_count_reconciliation(model, parent_models) %}

WITH parent_rows AS (
    -- Calculate the total expected rows from all parent models
    SELECT
        {% for parent_model in parent_models %}
        (SELECT COUNT(*) FROM {{ parent_model }})
        {% if not loop.last %}+{% endif %}
        {% endfor %}
        AS total_rows
),

child_rows AS (
    -- Calculate the actual number of rows in the child model
    SELECT
        COUNT(*) as total_rows
    FROM {{ model }}
)

-- The test fails if the counts do not match
SELECT *
FROM parent_rows p, child_rows c
WHERE p.total_rows != c.total_rows

{% endmacro %}
