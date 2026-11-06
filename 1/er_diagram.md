# ER-диаграмма: система управления складом

Модель содержит шесть таблиц.
`PK` — первичный ключ, `FK` — внешний, `UK` — одиночный уникальный ключ;
`||` означает ровно одну запись, `o{` — от нуля до многих, `o|` — ноль или одну.

```mermaid
erDiagram
    warehouses ||--o{ storage_cells : contains
    suppliers o|--o{ documents : supplies_IN
    documents ||--o{ document_lines : includes
    products ||--o{ document_lines : moved
    storage_cells ||--o{ document_lines : stores

    warehouses {
        bigint warehouse_id PK
        varchar code UK
        varchar name
        text address
    }
    storage_cells {
        bigint cell_id PK
        bigint warehouse_id FK
        varchar code
    }
    products {
        bigint product_id PK
        varchar sku UK
        varchar name
        varchar unit
        numeric min_stock
        numeric max_stock
    }
    suppliers {
        bigint supplier_id PK
        varchar name
        varchar tax_id UK
        varchar phone "nullable"
    }
    documents {
        bigint document_id PK
        varchar document_type "IN or OUT"
        varchar document_no
        date document_on
        bigint supplier_id FK "required for IN"
        varchar recipient_name "required for OUT"
    }
    document_lines {
        bigint document_id PK,FK
        integer line_no PK
        bigint product_id FK
        bigint cell_id FK
        numeric quantity
        numeric unit_price
    }
```

Составные ограничения:

- `PRIMARY KEY (document_id, line_no)` — строка уникальна в документе.
- `UNIQUE (warehouse_id, code)` — код ячейки уникален внутри склада.
- `UNIQUE (document_type, document_no)` — номер уникален в пределах типа документа.

Для `IN` обязателен `supplier_id`, а `recipient_name` равен NULL;
для `OUT` обязателен непустой `recipient_name`, а `supplier_id` равен NULL.
Эти условия задаёт `CHECK` реквизитов.
Остальные атрибуты обязательны, кроме `suppliers.phone`.
Цена строки — закупочная для IN и отпускная для OUT.

`stock_balances` — вычисляемое представление, в число шести таблиц не входит;
оно содержит товар, ячейку и разность сумм поступлений и отгрузок.
