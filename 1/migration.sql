SELECT
    w.warehouse_id,
    w.code,
    w.name,
    COUNT(DISTINCT dl.product_id) AS uniq_products_count,
    COUNT(DISTINCT dl.document_id) AS document_count,
    COUNT(DISTINCT d.supplier_id) AS uniq_suppliers_count
FROM warehouses AS w
LEFT JOIN storage_cells AS sc
    ON sc.warehouse_id = w.warehouse_id
LEFT JOIN document_lines AS dl
    ON dl.cell_id = sc.cell_id
LEFT JOIN documents AS d
    ON d.document_id = dl.document_id
GROUP BY
    w.warehouse_id,
    w.code,
    w.name
ORDER BY
    w.warehouse_id;