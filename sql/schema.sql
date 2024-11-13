CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    surname VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(50),
    password_hash TEXT
);

CREATE TABLE user_addresses (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    address TEXT NOT NULL
);

CREATE TABLE user_cards (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    number VARCHAR(19) NOT NULL
);

CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    method VARCHAR(50) NOT NULL,
    status TEXT NOT NULL
);

CREATE TABLE couriers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    rating DECIMAL(5, 2) NOT NULL
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_address TEXT,
    target_address TEXT,
    courier_id INTEGER REFERENCES couriers(id) ON DELETE SET NULL,
    status TEXT,
    payment_id INTEGER REFERENCES payments(id) ON DELETE SET NULL
);

CREATE TABLE suppliers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    work_time_start TIME NOT NULL,
    work_time_end TIME NOT NULL,
    rating DECIMAL(5, 2) NOT NULL,
    address TEXT NOT NULL
);

CREATE TABLE dishes (
    id SERIAL PRIMARY KEY,
    supplier_id INTEGER NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    cost BIGINT NOT NULL,
    image BYTEA,
    ingredients TEXT,
    weight INTEGER NOT NULL,
    calories INTEGER NOT NULL,
    allergens TEXT NOT NULL,
    rating DECIMAL(5, 2) NOT NULL
);

CREATE TABLE commodities (
    id SERIAL PRIMARY KEY,
    supplier_id INTEGER NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    cost BIGINT NOT NULL,
    image BYTEA,
    ingredients TEXT NOT NULL,
    weight INTEGER NOT NULL,
    rating DECIMAL(5, 2) NOT NULL
);

CREATE TABLE orders_composition (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    dish_id INTEGER REFERENCES dishes(id) ON DELETE CASCADE,
    commodity_id INTEGER REFERENCES commodities(id) ON DELETE CASCADE
);

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE categories_to_targets (
    id SERIAL PRIMARY KEY,
    dish_id INTEGER REFERENCES dishes(id) ON DELETE CASCADE,
    commodity_id INTEGER REFERENCES commodities(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE
);

/*
CREATE TABLE discounts (
    discount_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    percentage DECIMAL(5, 2) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL
);
*/
