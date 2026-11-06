BEGIN;

CREATE TABLE warehouses (
    warehouse_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code varchar(20) NOT NULL,
    name varchar(150) NOT NULL,
    address text NOT NULL,
    uniq_products_count bigint,
    document_count bigint,
    uniq_suppliers_count bigint,
    UNIQUE (code),
    CHECK (btrim(code) <> ''),
    CHECK (btrim(name) <> ''),
    CHECK (btrim(address) <> '')
);

CREATE TABLE storage_cells (
    cell_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_id bigint NOT NULL,
    code varchar(20) NOT NULL,
    UNIQUE (warehouse_id, code),
    CHECK (btrim(code) <> ''),
    FOREIGN KEY (warehouse_id)
        REFERENCES warehouses (warehouse_id) ON DELETE RESTRICT
);

CREATE TABLE products (
    product_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku varchar(40) NOT NULL,
    name varchar(150) NOT NULL,
    unit varchar(5) NOT NULL,
    min_stock numeric(12, 3) NOT NULL DEFAULT 0,
    max_stock numeric(12, 3) NOT NULL,
    UNIQUE (sku),
    CHECK (btrim(sku) <> ''),
    CHECK (btrim(name) <> ''),
    CHECK (unit IN ('шт', 'кг', 'л', 'м')),
    CHECK (min_stock >= 0),
    CHECK (max_stock >= min_stock)
);

CREATE TABLE suppliers (
    supplier_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(150) NOT NULL,
    tax_id varchar(12) NOT NULL,
    phone varchar(30),
    UNIQUE (tax_id),
    CHECK (btrim(name) <> '')
);

CREATE TABLE documents (
    document_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    document_type varchar(3) NOT NULL,
    document_no varchar(30) NOT NULL,
    document_on date NOT NULL,
    supplier_id bigint,
    recipient_name varchar(150),
    UNIQUE (document_type, document_no),
    CHECK (document_type IN ('IN', 'OUT')),
    CHECK (btrim(document_no) <> ''),
    -- IN: обязателен поставщик; OUT: обязательно непустое имя получателя.
    CHECK (
        (document_type = 'IN' AND supplier_id IS NOT NULL AND recipient_name IS NULL)
        OR
        (document_type = 'OUT' AND supplier_id IS NULL
            AND recipient_name IS NOT NULL AND btrim(recipient_name) <> '')
    ),
    FOREIGN KEY (supplier_id)
        REFERENCES suppliers (supplier_id) ON DELETE RESTRICT
);

CREATE TABLE document_lines (
    document_id bigint NOT NULL,
    line_no integer NOT NULL,
    product_id bigint NOT NULL,
    cell_id bigint NOT NULL,
    quantity numeric(12, 3) NOT NULL,
    unit_price numeric(12, 2) NOT NULL,
    PRIMARY KEY (document_id, line_no),
    CHECK (line_no > 0),
    CHECK (quantity > 0),
    CHECK (unit_price >= 0),
    FOREIGN KEY (document_id)
        REFERENCES documents (document_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id)
        REFERENCES products (product_id) ON DELETE RESTRICT,
    FOREIGN KEY (cell_id)
        REFERENCES storage_cells (cell_id) ON DELETE RESTRICT
);

CREATE VIEW stock_balances AS
SELECT l.product_id, l.cell_id,
       sum(CASE WHEN d.document_type = 'IN' THEN l.quantity ELSE -l.quantity END) AS quantity
FROM document_lines AS l
JOIN documents AS d ON d.document_id = l.document_id
GROUP BY l.product_id, l.cell_id;

COMMIT;
