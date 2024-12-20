-- Найти все карты по которым не прошла оплата и вывести инфо об этой операции
SELECT uc.*, p.timestamp as payment_time, p.status as payment_status, o.id as order_id
FROM user_cards uc
JOIN payments p ON uc.id = p.card_id
JOIN orders o ON p.id = o.payment_id
WHERE p.status = 'failed';

-- Найти все блюда которые были заказаны с определенной даты по какую-то дату и вывести инфо о заказе
SELECT d.*, o.timestamp as order_time, o.status as order_status,
       o.source_address, o.target_address
FROM dishes d
JOIN orders_composition oc ON d.id = oc.dish_id
JOIN orders o ON oc.order_id = o.id
WHERE o.timestamp BETWEEN '2024-03-01' AND '2024-03-31';

-- Найти заведение из которого было заказано больше всего блюд за все время
SELECT s.*, COUNT(oc.dish_id) as total_dishes_ordered
FROM suppliers s
JOIN dishes d ON s.id = d.supplier_id
JOIN orders_composition oc ON d.id = oc.dish_id
GROUP BY s.id
ORDER BY total_dishes_ordered DESC
LIMIT 1;

-- Найти всех клиентов у которых фамилия начинается на определенную букву
SELECT *
FROM users
WHERE surname LIKE 'А%';

-- Найти пользователей, которые никогда не платили картой
SELECT u.*
FROM users u
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    JOIN payments p ON o.payment_id = p.id
    WHERE o.user_id = u.id
    AND p.card_id IS NOT NULL
);

-- Найти клиентов, которые заказывают доставку только на один адрес
SELECT u.*, COUNT(DISTINCT o.target_address) as delivery_addresses
FROM users u
JOIN orders o ON u.id = o.user_id
GROUP BY u.id
HAVING COUNT(DISTINCT o.target_address) = 1;

-- Найти 1 категорию, в которой было заказано больше всего блюд за все время
SELECT c.*, COUNT(oc.dish_id) as dishes_ordered
FROM categories c
JOIN categories_to_targets ct ON c.id = ct.category_id
JOIN dishes d ON ct.dish_id = d.id
JOIN orders_composition oc ON d.id = oc.dish_id
GROUP BY c.id
ORDER BY dishes_ordered DESC
LIMIT 1;

-- Найти среднее количество блюд на продавца
SELECT AVG(dish_count) as avg_dishes_per_supplier
FROM (
    SELECT supplier_id, COUNT(id) as dish_count
    FROM dishes
    GROUP BY supplier_id
) supplier_dishes;

-- Найти поставщиков, у которых средний рейтинг блюд выше среднего рейтинга по всем блюдам
WITH avg_rating AS (
    SELECT AVG(rating) as avg_dish_rating
    FROM dishes
)
SELECT s.*, AVG(d.rating) as supplier_avg_rating
FROM suppliers s
JOIN dishes d ON s.id = d.supplier_id
CROSS JOIN avg_rating ar
GROUP BY s.id, ar.avg_dish_rating
HAVING AVG(d.rating) > ar.avg_dish_rating;

-- Найти месяц в 2024 году с наибольшим количеством заказов для каждого поставщика
WITH monthly_orders AS (
    SELECT s.id as supplier_id,
           DATE_TRUNC('month', o.timestamp) as month,
           COUNT(*) as order_count,
           RANK() OVER (PARTITION BY s.id ORDER BY COUNT(*) DESC) as month_rank
    FROM suppliers s
    JOIN dishes d ON s.id = d.supplier_id
    JOIN orders_composition oc ON d.id = oc.dish_id
    JOIN orders o ON oc.order_id = o.id
    WHERE EXTRACT(YEAR FROM o.timestamp) = 2024
    GROUP BY s.id, DATE_TRUNC('month', o.timestamp)
)
SELECT s.*, mo.month, mo.order_count
FROM suppliers s
JOIN monthly_orders mo ON s.id = mo.supplier_id
WHERE mo.month_rank = 1;

-- Определить пользователей, которые никогда не использовали свои сохраненные адреса для заказов
SELECT DISTINCT u.*
FROM users u
JOIN user_addresses ua ON u.id = ua.user_id
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.user_id = u.id
    AND o.target_address = ua.address
);

-- Найти поставщиков с наибольшей разницей в цене между их самым дорогим и самым дешевым блюдом
SELECT s.*,
       MAX(d.cost) - MIN(d.cost) as price_difference,
       MAX(d.cost) as max_price,
       MIN(d.cost) as min_price
FROM suppliers s
JOIN dishes d ON s.id = d.supplier_id
GROUP BY s.id
ORDER BY price_difference DESC;

-- Найти пользователей, сделавших более 3 заказов И средняя сумма заказа которых выше 1000
SELECT u.*,
       COUNT(DISTINCT o.id) as order_count,
       AVG(d.cost + COALESCE(c.cost, 0)) as avg_order_sum
FROM users u
JOIN orders o ON u.id = o.user_id
JOIN orders_composition oc ON o.id = oc.order_id
LEFT JOIN dishes d ON oc.dish_id = d.id
LEFT JOIN commodities c ON oc.commodity_id = c.id
GROUP BY u.id
HAVING COUNT(DISTINCT o.id) > 3
   AND AVG(d.cost + COALESCE(c.cost, 0)) > 1000;

-- Категоризировать пользователей по частоте заказов за последний месяц: активные (> 5), средние (2-5), редкие (< 2)
SELECT u.*,
       COUNT(o.id) as orders_last_month,
       CASE
           WHEN COUNT(o.id) > 5 THEN 'active'
           WHEN COUNT(o.id) >= 2 THEN 'average'
           ELSE 'rare'
       END as user_category
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
   AND o.timestamp >= (CURRENT_DATE - INTERVAL '1 month')
GROUP BY u.id;
