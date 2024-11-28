-- name: CreateUsers :copyfrom
INSERT INTO users (name, surname, email, phone, password_hash)
VALUES (@name, @surname, @email, @phone, @password_hash);

-- name: SelectUserIDs :many
SELECT id FROM users;

-- name: CreateUserAddresses :copyfrom
INSERT INTO user_addresses (user_id, address)
VALUES (@user_id, @address);

-- name: CreateUserCards :copyfrom
INSERT INTO user_cards (user_id, number)
VALUES (@user_id, @number);

-- name: SelectUserCardIDs :many
SELECT id FROM user_cards;

-- name: CreateOrders :copyfrom
INSERT INTO orders (user_id, timestamp, source_address, target_address, courier_id, status, payment_id)
VALUES (@user_id, @timestamp, @source_address, @target_address, @courier_id, @status, @payment_id);

-- name: SelectOrderIDs :many
SELECT id FROM orders;

-- name: AssignOrdersCommoditiesAndDishes :copyfrom
INSERT INTO orders_composition (order_id, dish_id, commodity_id)
VALUES (@order_id, sqlc.narg('dish_id'), sqlc.narg('commodity_id'));

-- name: CreatePayments :copyfrom
INSERT INTO payments (method, card_id, timestamp, status)
VALUES (@method, @card_id, @timestamp, @status);

-- name: SelectPaymentIDs :many
SELECT id FROM payments;

-- name: CreateCourieres :copyfrom
INSERT INTO couriers (name, phone, rating)
VALUES (@name, @phone, @rating);

-- name: SelectCourierIDs :many
SELECT id FROM couriers;

-- name: CreateDishes :copyfrom
INSERT INTO dishes (supplier_id, name, cost, image, ingredients, weight, calories, allergens, rating)
VALUES (@supplier_id, @name, @cost, @image, @ingredients, @weight, @calories, @allergens, @rating);

-- name: SelectDishIDs :many
SELECT id FROM dishes;

-- name: CreateCommodities :copyfrom
INSERT INTO commodities (supplier_id, name, cost, image, ingredients, weight, rating)
VALUES (@supplier_id, @name, @cost, @image, @ingredients, @weight, @rating);

-- name: SelectCommodityIDs :many
SELECT id FROM commodities;

-- name: CreateCategories :copyfrom
INSERT INTO categories (name)
VALUES (@name);

-- name: SelectCategoryIDs :many
SELECT id FROM categories;

-- name: AssignCategoriesToTargets :copyfrom
INSERT INTO categories_to_targets (dish_id, commodity_id, category_id)
VALUES (sqlc.narg('dish_id'), sqlc.narg('commodity_id'), @category_id);

-- name: CreateSuppliers :copyfrom
INSERT INTO suppliers (name, work_time_start, work_time_end, rating, address)
VALUES (@name, @work_time_start, @work_time_end, @rating, @address);

-- name: SelectSupplierIDs :many
SELECT id FROM suppliers;

-- name: CreateDiscounts :copyfrom
INSERT INTO discounts (name, description, type, terms, active)
VALUES (@name, @description, @type, @terms, @active);

-- name: SelectDiscountIDs :many
SELECT id FROM discounts;

-- name: CreateDiscountTargets :copyfrom
INSERT INTO discount_to_targets (dish_id, commodity_id, discount_id)
VALUES (sqlc.narg('dish_id'), sqlc.narg('commodity_id'), @discount_id);
