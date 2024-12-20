-- Найти всех поставщиков определенного товара и вывести о поставщиках инфо
SELECT DISTINCT s.*
FROM suppliers s
INNER JOIN commodities c ON s.id = c.supplier_id
WHERE c.name = 'Конкретный товар';

-- Найти все заказы сделанные за последний месяц и вывести по ним инфу
SELECT o.*, p.method as payment_method, p.status as payment_status,
       c.name as courier_name, c.rating as courier_rating
FROM orders o
LEFT JOIN payments p ON o.payment_id = p.id
LEFT JOIN couriers c ON o.courier_id = c.id
WHERE o.timestamp >= (CURRENT_DATE - INTERVAL '1 month')
ORDER BY o.timestamp DESC;

-- Найти клиента который заказал на максимальную сумму за все время (без учета скидок)
WITH order_totals AS (
    SELECT o.user_id,
           SUM(COALESCE(d.cost, 0) + COALESCE(c.cost, 0)) as total_spent
    FROM orders o
    LEFT JOIN orders_composition oc ON o.id = oc.order_id
    LEFT JOIN dishes d ON oc.dish_id = d.id
    LEFT JOIN commodities c ON oc.commodity_id = c.id
    GROUP BY o.user_id
    ORDER BY total_spent DESC
    LIMIT 1
)
SELECT u.*, ot.total_spent
FROM users u
JOIN order_totals ot ON u.id = ot.user_id;

-- Найти все блюда в составе которого есть определенный ингредиент
SELECT *
FROM dishes
WHERE ingredients LIKE '%Искомый ингредиент%';

-- Найти блюда конкретного поставщика, которое не было заказано за последнюю неделю
SELECT d.*
FROM dishes d
WHERE d.supplier_id = 1
AND d.id NOT IN (
    SELECT DISTINCT oc.dish_id
    FROM orders_composition oc
    JOIN orders o ON oc.order_id = o.id
    WHERE o.timestamp >= (CURRENT_DATE - INTERVAL '1 week')
);

-- Найти клиентов, которые делают заказы только из одного заведения
SELECT u.*, COUNT(DISTINCT d.supplier_id) as supplier_count
FROM users u
JOIN orders o ON u.id = o.user_id
JOIN orders_composition oc ON o.id = oc.order_id
JOIN dishes d ON oc.dish_id = d.id
GROUP BY u.id
HAVING COUNT(DISTINCT d.supplier_id) = 1;

-- Найти 3 клиента у которых макс сумма заказов по цене за все время
SELECT u.*, SUM(COALESCE(d.cost, 0) + COALESCE(c.cost, 0)) as total_spent
FROM users u
JOIN orders o ON u.id = o.user_id
JOIN orders_composition oc ON o.id = oc.order_id
LEFT JOIN dishes d ON oc.dish_id = d.id
LEFT JOIN commodities c ON oc.commodity_id = c.id
GROUP BY u.id
ORDER BY total_spent DESC
LIMIT 3;

-- Найти среднее количество заказов клиента в месяц
WITH user_monthly_orders AS (
    SELECT user_id,
           DATE_TRUNC('month', timestamp) as month,
           COUNT(*) as orders_count
    FROM orders
    GROUP BY user_id, DATE_TRUNC('month', timestamp)
)
SELECT user_id, AVG(orders_count) as avg_monthly_orders
FROM user_monthly_orders
GROUP BY user_id;

-- Найти топ-3 поставщиков по среднему рейтингу их блюд и товаров вместе
WITH combined_ratings AS (
    SELECT supplier_id,
           AVG(rating) as avg_rating,
           COUNT(*) as total_items
    FROM (
        SELECT supplier_id, rating FROM dishes
        UNION ALL
        SELECT supplier_id, rating FROM commodities
    ) all_items
    GROUP BY supplier_id
)
SELECT s.*, cr.avg_rating, cr.total_items
FROM suppliers s
JOIN combined_ratings cr ON s.id = cr.supplier_id
ORDER BY cr.avg_rating DESC
LIMIT 3;

-- Найти пользователей и количество их заказов за каждый месяц 2024 года
SELECT u.id, u.name, u.surname,
       DATE_TRUNC('month', o.timestamp) as month,
       COUNT(*) as orders_count
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE EXTRACT(YEAR FROM o.timestamp) = 2024
GROUP BY u.id, u.name, u.surname, DATE_TRUNC('month', o.timestamp)
ORDER BY u.id, month;

-- Найти пользователей, у которых есть и сохраненные адреса, и привязанные карты
SELECT u.*,
       COUNT(DISTINCT ua.id) as address_count,
       COUNT(DISTINCT uc.id) as card_count
FROM users u
JOIN user_addresses ua ON u.id = ua.user_id
JOIN user_cards uc ON u.id = uc.user_id
GROUP BY u.id;

-- Найти блюда, которые есть у более чем 2 поставщиков, и их среднюю цену
SELECT d.name,
       COUNT(DISTINCT d.supplier_id) as supplier_count,
       AVG(d.cost) as avg_cost
FROM dishes d
GROUP BY d.name
HAVING COUNT(DISTINCT d.supplier_id) > 2;

-- Найти поставщиков, у которых средний рейтинг блюд выше 4.5 И количество блюд больше 5
SELECT s.*,
       AVG(d.rating) as avg_dish_rating,
       COUNT(d.id) as dish_count
FROM suppliers s
JOIN dishes d ON s.id = d.supplier_id
GROUP BY s.id
HAVING AVG(d.rating) > 4.5 AND COUNT(d.id) > 5;

-- Классифицировать поставщиков по количеству блюд: мало (< 5), средне (5-15), много (> 15)
SELECT s.*,
       COUNT(d.id) as dish_count,
       CASE
           WHEN COUNT(d.id) < 5 THEN 'low'
           WHEN COUNT(d.id) <= 15 THEN 'medium'
           ELSE 'high'
       END as size_category
FROM suppliers s
LEFT JOIN dishes d ON s.id = d.supplier_id
GROUP BY s.id
ORDER BY dish_count;
