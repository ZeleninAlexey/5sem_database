-- Выполнять один раз после schema.sql.
BEGIN;

INSERT INTO warehouses (code, name, address) VALUES
    ('MSK', 'Основной склад', 'Москва, Складская улица, 1'),
    ('TVER', 'Региональный склад', 'Тверь, Промышленная улица, 10');

INSERT INTO storage_cells (warehouse_id, code)
SELECT w.warehouse_id, v.cell_code
FROM (VALUES
    ('MSK', 'A-01'), ('MSK', 'A-02'), ('MSK', 'B-01'),
    ('TVER', 'A-01'), ('TVER', 'B-01')
) AS v(warehouse_code, cell_code)
JOIN warehouses AS w ON w.code = v.warehouse_code;

INSERT INTO products (sku, name, unit, min_stock, max_stock) VALUES
    ('BOLT-M8', 'Болт М8', 'шт', 50, 1000),
    ('NUT-M8', 'Гайка М8', 'шт', 50, 1000),
    ('PAINT-W', 'Краска белая', 'л', 10, 200),
    ('CABLE-3', 'Кабель трёхжильный', 'м', 20, 500),
    ('SAND-Q', 'Песок кварцевый', 'кг', 100, 5000);

INSERT INTO suppliers (name, tax_id, phone) VALUES
    ('Метиз-Снаб', '7701234567', '+7 495 111-22-33'),
    ('Стройматериалы', '6901234567', '+7 495 444-55-66'),
    ('Кабель-Торг', '770123456789', NULL);

INSERT INTO documents (document_type, document_no, document_on, supplier_id)
SELECT 'IN', v.document_no, v.document_on, s.supplier_id
FROM (VALUES
    ('IN-001', '7701234567', DATE '2026-10-01'),
    ('IN-002', '6901234567', DATE '2026-10-02'),
    ('IN-003', '770123456789', DATE '2026-10-03'),
    ('IN-004', '7701234567', DATE '2026-10-04')
) AS v(document_no, tax_id, document_on)
JOIN suppliers AS s ON s.tax_id = v.tax_id;

INSERT INTO documents (document_type, document_no, document_on, recipient_name) VALUES
    ('OUT', 'OUT-001', DATE '2026-10-05', 'Строительная компания Альфа'),
    ('OUT', 'OUT-002', DATE '2026-10-06', 'Мастерская Бета'),
    ('OUT', 'OUT-003', DATE '2026-10-07', 'Монтажная компания Гамма');

-- Цена закупки для IN, отпускная цена для OUT.
INSERT INTO document_lines
    (document_id, line_no, product_id, cell_id, quantity, unit_price)
SELECT d.document_id, v.line_no, p.product_id, c.cell_id, v.quantity, v.unit_price
FROM (VALUES
    ('IN', 'IN-001', 1, 'BOLT-M8', 'MSK', 'A-01', 500.000, 12.50),
    ('IN', 'IN-001', 2, 'NUT-M8', 'MSK', 'A-01', 500.000, 5.00),
    ('IN', 'IN-002', 1, 'PAINT-W', 'MSK', 'B-01', 80.000, 250.00),
    ('IN', 'IN-002', 2, 'SAND-Q', 'TVER', 'B-01', 1200.000, 18.00),
    ('IN', 'IN-003', 1, 'CABLE-3', 'MSK', 'A-02', 150.500, 75.00),
    ('IN', 'IN-004', 1, 'BOLT-M8', 'TVER', 'A-01', 200.000, 13.00),
    ('IN', 'IN-004', 2, 'BOLT-M8', 'MSK', 'A-01', 100.000, 13.00),
    ('OUT', 'OUT-001', 1, 'BOLT-M8', 'MSK', 'A-01', 120.000, 18.00),
    ('OUT', 'OUT-001', 2, 'NUT-M8', 'MSK', 'A-01', 120.000, 8.00),
    ('OUT', 'OUT-002', 1, 'PAINT-W', 'MSK', 'B-01', 15.000, 320.00),
    ('OUT', 'OUT-002', 2, 'SAND-Q', 'TVER', 'B-01', 250.000, 25.00),
    ('OUT', 'OUT-003', 1, 'CABLE-3', 'MSK', 'A-02', 40.250, 110.00),
    ('OUT', 'OUT-003', 2, 'BOLT-M8', 'TVER', 'A-01', 50.000, 18.00)
) AS v(document_type, document_no, line_no, sku, warehouse_code, cell_code, quantity, unit_price)
JOIN documents AS d ON d.document_type = v.document_type AND d.document_no = v.document_no
JOIN products AS p ON p.sku = v.sku
JOIN warehouses AS w ON w.code = v.warehouse_code
JOIN storage_cells AS c ON c.warehouse_id = w.warehouse_id AND c.code = v.cell_code;

COMMIT;
