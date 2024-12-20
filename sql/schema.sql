CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    surname VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(50),
    password_hash TEXT
);

CREATE INDEX users_surname on users USING GIN (surname);

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

CREATE INDEX user_cards_user_id ON user_cards USING HASH (user_id);

CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    method VARCHAR(50) NOT NULL,
    card_id INTEGER REFERENCES user_cards(id) ON DELETE SET NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT NOT NULL
);

CREATE INDEX payments_method ON payments (method);
CREATE INDEX payments_status ON payments (status);

CREATE TABLE couriers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    rating DECIMAL(5, 2) NOT NULL
);

CREATE TABLE discounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    type VARCHAR(32) NOT NULL,
    terms JSONB NOT NULL,
    active BOOLEAN NOT NULL
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_address TEXT,
    target_address TEXT,
    courier_id INTEGER REFERENCES couriers(id) ON DELETE SET NULL,
    status TEXT,
    payment_id INTEGER REFERENCES payments(id) ON DELETE SET NULL,
    discount_id INTEGER REFERENCES discounts(id) ON DELETE SET NULL
);

CREATE INDEX orders_timestamps ON orders (timestamp);
CREATE INDEX orders_user_id ON orders USING HASH (user_id);

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

CREATE INDEX dishes_ingredients on dishes USING GIN (ingredients);
CREATE INDEX dishes_supplier_id on dishes USING HASH (supplier_id);

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

CREATE INDEX commodities_supplier_id ON commodities USING HASH (supplier_id);
CREATE INDEX commodities_supplier_name ON commodities USING HASH (name);

CREATE TABLE orders_composition (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    dish_id INTEGER REFERENCES dishes(id) ON DELETE CASCADE,
    commodity_id INTEGER REFERENCES commodities(id) ON DELETE CASCADE
);

CREATE INDEX order_composition_target_order_id ON orders_composition USING HASH (order_id);
CREATE INDEX order_composition_target_dish_id ON orders_composition USING HASH (dish_id);
CREATE INDEX order_composition_target_commodity_id ON orders_composition USING HASH (commodity_id);

CREATE TABLE discount_to_targets (
    id SERIAL PRIMARY KEY,
    dish_id INTEGER REFERENCES dishes(id) ON DELETE CASCADE,
    commodity_id INTEGER REFERENCES commodities(id) ON DELETE CASCADE,
    discount_id INTEGER NOT NULL REFERENCES discounts(id) ON DELETE CASCADE
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

CREATE INDEX orders_timestamp_year_month ON orders USING BTREE (EXTRACT(YEAR FROM timestamp), EXTRACT(MONTH FROM timestamp));
CREATE INDEX orders_timestamp_hour ON orders USING BTREE (EXTRACT(HOUR FROM timestamp));

CREATE INDEX suppliers_address ON suppliers USING GIN (address gin_trgm_ops);
CREATE INDEX orders_target_address ON orders USING BTREE (target_address);

CREATE INDEX users_surname_prefix ON users USING BTREE (surname text_pattern_ops);
CREATE INDEX dishes_name_prefix ON dishes USING BTREE (name text_pattern_ops);
CREATE INDEX commodities_name_prefix ON commodities USING BTREE (name text_pattern_ops);

CREATE INDEX dishes_rating ON dishes USING BTREE (rating);
CREATE INDEX commodities_rating ON commodities USING BTREE (rating);

CREATE INDEX dishes_cost ON dishes USING BTREE (cost);
CREATE INDEX commodities_cost ON commodities USING BTREE (cost);

CREATE INDEX orders_user_timestamp ON orders USING BTREE (user_id, timestamp);
CREATE INDEX orders_composition_order_dish ON orders_composition USING BTREE (order_id, dish_id);
CREATE INDEX orders_composition_order_commodity ON orders_composition USING BTREE (order_id, commodity_id);
