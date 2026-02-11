-- This model creates a rich view for medical stock. It cleans supplier IDs
-- to ensure accurate joins and handles any remaining nulls gracefully.

WITH medical_stock AS (

    -- Select from the silver-layer table and clean the supplier_id by removing the prefix
    SELECT
        *,
        REPLACE(supplier_id, 'H3-', '') AS cleaned_supplier_id
    FROM {{ ref('medical_stock') }}

),

suppliers AS (

    -- Select from the suppliers table and also clean the supplier_id for a robust join
    SELECT
        REPLACE(supplier_id, 'H3-', '') AS cleaned_supplier_id,
        name AS supplier_name
    FROM {{ ref('supplier') }}
    -- Deduplicate to ensure we have one unique name per supplier ID
    QUALIFY ROW_NUMBER() OVER(PARTITION BY cleaned_supplier_id ORDER BY supplier_name) = 1

),

final AS (

    SELECT
        ROW_NUMBER() OVER(ORDER BY stock.medicine_id, stock.batch_number) AS id,
        stock.medicine_id,
        stock.medicine_name AS name,
        stock.category,
        stock.cleaned_supplier_id AS supplier_id, -- Use the cleaned ID for the final output

        -- THIS IS THE FIX for NULLs: If the join fails, show 'Unknown Supplier' instead of NULL.
        COALESCE(sup.supplier_name, 'Unknown Supplier') AS supplier_name,

        stock.cost_price,
        stock.unit_price,
        stock.stock_quantity,
        
        DAYNAME(stock.expiry_date) || ', ' || TO_VARCHAR(stock.expiry_date, 'MMMM DD, YYYY') AS expiry_date,
        DAYNAME(stock.manufacture_date) || ', ' || TO_VARCHAR(stock.manufacture_date, 'MMMM DD, YYYY') AS manufacture_date,
        
        stock.batch_number,
        stock.reorder_level

    FROM medical_stock AS stock
    -- Join on the cleaned supplier IDs from both tables to ensure matches
    LEFT JOIN suppliers AS sup ON stock.cleaned_supplier_id = sup.cleaned_supplier_id
)

SELECT *
FROM final
