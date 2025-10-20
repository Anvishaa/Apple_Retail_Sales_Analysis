-- designing schema --
-- CREATING TABLES--
CREATE TABLE category (
    category_id VARCHAR(6) PRIMARY KEY ,
    category_name text
);

CREATE TABLE products (
    product_id VARCHAR(5) PRIMARY KEY,
    product_name TEXT,
    category_id VARCHAR(6),
    launch_date TEXT,
    price INTEGER,
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

CREATE TABLE stores (
    store_id VARCHAR(5) PRIMARY KEY,
    store_name TEXT,
    city TEXT,
    country TEXT
);

CREATE TABLE sales (
    sale_id VARCHAR(10) PRIMARY KEY,
    sale_date TEXT,
    store_id VARCHAR(5),
    product_id VARCHAR(5),
    quantity INTEGER,
    FOREIGN KEY(store_id) REFERENCES stores(store_id),
    FOREIGN KEY(product_id) REFERENCES products(product_id)
);

CREATE TABLE warranty (
    claim_id VARCHAR(9) PRIMARY KEY,
    claim_date TEXT,
    sale_id VARCHAR(10),
    repair_status TEXT CHECK (repair_status IN ('Pending', 'Completed', 'Rejected', 'In Progress')),
    FOREIGN KEY (sale_id) REFERENCES sales(sale_id)
);


