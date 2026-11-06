-- Выполнять после schema.sql и data.sql.
-- Каждая ошибка перехватывается в под-транзакции функции, поэтому следующие
-- проверки продолжаются; неожиданный результат вызывает исключение.
BEGIN;

CREATE FUNCTION pg_temp.expect_rejection(
    statement text, expected_state text
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE statement;
    EXCEPTION WHEN integrity_constraint_violation THEN
        IF SQLSTATE <> expected_state THEN
            RAISE EXCEPTION 'Ожидался SQLSTATE %, получен %: %',
                expected_state, SQLSTATE, SQLERRM;
        END IF;
        RAISE NOTICE 'OK: SQLSTATE %', SQLSTATE;
        RETURN;
    END;
    RAISE EXCEPTION 'Операция неожиданно выполнена: %', statement;
END;
$$;

-- 1. Повторный артикул.
SELECT pg_temp.expect_rejection(
    $$INSERT INTO products (sku, name, unit, max_stock) VALUES ('BOLT-M8', 'Дубликат', 'шт', 100)$$,
    '23505');

-- 2. Повторная ячейка внутри склада.
SELECT pg_temp.expect_rejection(
    $$INSERT INTO storage_cells (warehouse_id, code) SELECT warehouse_id, 'A-01' FROM warehouses WHERE code = 'MSK'$$,
    '23505');

-- 3. Отсутствует обязательное название склада.
SELECT pg_temp.expect_rejection(
    $$INSERT INTO warehouses (code, name, address) VALUES ('INVALID', NULL, 'Москва')$$,
    '23502');

-- 4. Ссылка на несуществующий склад.
SELECT pg_temp.expect_rejection(
    $$INSERT INTO storage_cells (warehouse_id, code) VALUES (-1, 'X-01')$$,
    '23503');

-- 5. Нулевое количество.
SELECT pg_temp.expect_rejection(
    $$UPDATE document_lines SET quantity = 0 WHERE document_id = (SELECT document_id FROM documents WHERE document_type = 'IN' AND document_no = 'IN-001') AND line_no = 1$$,
    '23514');

-- 6. Отрицательная цена.
SELECT pg_temp.expect_rejection(
    $$UPDATE document_lines SET unit_price = -1 WHERE document_id = (SELECT document_id FROM documents WHERE document_type = 'IN' AND document_no = 'IN-001') AND line_no = 1$$,
    '23514');

-- 7. Максимальный запас ниже минимального.
SELECT pg_temp.expect_rejection(
    $$UPDATE products SET max_stock = min_stock - 1 WHERE sku = 'BOLT-M8'$$,
    '23514');

-- 8. Повторная строка документа.
SELECT pg_temp.expect_rejection(
    $$INSERT INTO document_lines (document_id, line_no, product_id, cell_id, quantity, unit_price) SELECT document_id, line_no, product_id, cell_id, quantity, unit_price FROM document_lines WHERE document_id = (SELECT document_id FROM documents WHERE document_type = 'IN' AND document_no = 'IN-001') AND line_no = 1$$,
    '23505');

-- 9. Недопустимая единица измерения.
SELECT pg_temp.expect_rejection(
    $$UPDATE products SET unit = 'ящик' WHERE sku = 'BOLT-M8'$$,
    '23514');

-- 10. Поступление без поставщика.
SELECT pg_temp.expect_rejection(
    $$UPDATE documents SET supplier_id = NULL WHERE document_type = 'IN' AND document_no = 'IN-001'$$,
    '23514');

-- 11. Отгрузка с пустым получателем.
SELECT pg_temp.expect_rejection(
    $$UPDATE documents SET recipient_name = '   ' WHERE document_type = 'OUT' AND document_no = 'OUT-001'$$,
    '23514');

-- 12. Повторный номер документа того же типа.
SELECT pg_temp.expect_rejection(
    $$INSERT INTO documents (document_type, document_no, document_on, recipient_name) VALUES ('OUT', 'OUT-001', DATE '2026-10-08', 'Другой получатель')$$,
    '23505');

-- Дополнительная проверка RESTRICT.
SELECT pg_temp.expect_rejection(
    $$DELETE FROM warehouses WHERE code = 'MSK'$$,
    '23503');

-- Дополнительная проверка CASCADE; изменения отменяются итоговым ROLLBACK.
DO $$
DECLARE
    target_id bigint;
BEGIN
    SELECT document_id INTO STRICT target_id FROM documents
    WHERE document_type = 'IN' AND document_no = 'IN-001';
    IF NOT EXISTS (SELECT 1 FROM document_lines WHERE document_id = target_id) THEN
        RAISE EXCEPTION 'Нет строк для проверки CASCADE';
    END IF;
    DELETE FROM documents WHERE document_id = target_id;
    IF EXISTS (SELECT 1 FROM document_lines WHERE document_id = target_id) THEN
        RAISE EXCEPTION 'ON DELETE CASCADE не удалил строки документа';
    END IF;
    RAISE NOTICE 'OK: ON DELETE CASCADE';
END;
$$;

ROLLBACK;
