-- Найти все товары определенного поставщика и вывести инфо о товарах
SELECT c.*
FROM commodities c
WHERE c.supplier_id = 1;

-- Найти всех курьеров которые работали в определенном месяце и году и вывести кол-во заказов
SELECT c.*,
       COUNT(o.id) as total_orders
FROM couriers c
JOIN orders o ON c.id = o.courier_id
WHERE EXTRACT(YEAR FROM o.timestamp) = 2024
  AND EXTRACT(MONTH FROM o.timestamp) = 3
GROUP BY c.id;

-- Найти блюдо которое было заказано меньше всего раз за все время
WITH dish_orders AS (
    SELECT d.id, d.name, COUNT(oc.order_id) as order_count
    FROM dishes d
    LEFT JOIN orders_composition oc ON d.id = oc.dish_id
    GROUP BY d.id, d.name
)
SELECT d.*, orders.order_count
FROM dishes d
JOIN dish_orders orders ON d.id = orders.id
WHERE orders.order_count = (
    SELECT MIN(order_count)
    FROM dish_orders
);

-- Найти все заведения на определенной улице
SELECT *
FROM suppliers
WHERE address LIKE '%Конкретная улица%';

-- Найти клиентов, которые никогда не заказывали из ресторанов
SELECT u.*
FROM users u
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    JOIN orders_composition oc ON o.id = oc.order_id
    JOIN dishes d ON oc.dish_id = d.id
    WHERE o.user_id = u.id
);

-- Найти блюда, которые предлагаются только в одном заведении
SELECT d.name, COUNT(DISTINCT d.supplier_id) as supplier_count
FROM dishes d
GROUP BY d.name
HAVING COUNT(DISTINCT d.supplier_id) = 1;

-- Найти 5 производителей, которые продали блюд на наименьшую сумму за последний месяц
SELECT s.*, COALESCE(SUM(d.cost), 0) as total_sales
FROM suppliers s
LEFT JOIN dishes d ON s.id = d.supplier_id
LEFT JOIN orders_composition oc ON d.id = oc.dish_id
LEFT JOIN orders o ON oc.order_id = o.id
WHERE o.timestamp >= (CURRENT_DATE - INTERVAL '1 month')
   OR o.timestamp IS NULL
GROUP BY s.id
ORDER BY total_sales ASC
LIMIT 5;

-- Найти среднее количество позиций в заказе
SELECT AVG(positions_count) as avg_positions_per_order
FROM (
    SELECT o.id, COUNT(oc.id) as positions_count
    FROM orders o
    LEFT JOIN orders_composition oc ON o.id = oc.order_id
    GROUP BY o.id
) order_positions;

-- Для каждого поставщика посчитать количество блюд и товаров в разных ценовых диапазонах
SELECT s.id, s.name,
       COUNT(CASE WHEN item_cost < 500 THEN 1 END) as low_price,
       COUNT(CASE WHEN item_cost BETWEEN 500 AND 1000 THEN 1 END) as medium_price,
       COUNT(CASE WHEN item_cost > 1000 THEN 1 END) as high_price
FROM suppliers s
LEFT JOIN (
    SELECT supplier_id, cost as item_cost FROM dishes
    UNION ALL
    SELECT supplier_id, cost FROM commodities
) all_items ON s.id = all_items.supplier_id
GROUP BY s.id, s.name;

-- Определить пользователей, которые сделали заказы во все месяцы 2024 года
WITH months_2024 AS (
    SELECT generate_series(
        '2024-01-01'::date,
        '2024-12-01'::date,
        '1 month'::interval
    ) as month
),
user_months AS (
    SELECT u.id,
           DATE_TRUNC('month', o.timestamp) as order_month
    FROM users u
    JOIN orders o ON u.id = o.user_id
    WHERE EXTRACT(YEAR FROM o.timestamp) = 2024
    GROUP BY u.id, DATE_TRUNC('month', o.timestamp)
)
SELECT u.*
FROM users u
WHERE (
    SELECT COUNT(DISTINCT order_month)
    FROM user_months
    WHERE user_months.id = u.id
) = (SELECT COUNT(*) FROM months_2024);

-- Найти пользователей, у которых больше 3 сохраненных адресов, но нет привязанных карт
SELECT u.*,
       COUNT(DISTINCT ua.id) as address_count
FROM users u
JOIN user_addresses ua ON u.id = ua.user_id
LEFT JOIN user_cards uc ON u.id = uc.user_id
WHERE uc.id IS NULL
GROUP BY u.id
HAVING COUNT(DISTINCT ua.id) > 3;

-- Определить поставщиков, у которых все блюда дороже средней цены по всем блюдам
WITH avg_price AS (
    SELECT AVG(cost) as avg_cost
    FROM dishes
)
SELECT s.*
FROM suppliers s
WHERE NOT EXISTS (
    SELECT 1
    FROM dishes d
    CROSS JOIN avg_price ap
    WHERE d.supplier_id = s.id
    AND d.cost <= ap.avg_cost
);

-- Найти категории, в которых есть более 10 блюд И средняя цена блюд выше общей средней цены
WITH avg_price AS (
    SELECT AVG(cost) as avg_cost
    FROM dishes
)
SELECT c.*,
       COUNT(DISTINCT d.id) as dish_count,
       AVG(d.cost) as avg_category_cost
FROM categories c
JOIN categories_to_targets ct ON c.id = ct.category_id
JOIN dishes d ON ct.dish_id = d.id
CROSS JOIN avg_price ap
GROUP BY c.id, ap.avg_cost
HAVING COUNT(DISTINCT d.id) > 10
   AND AVG(d.cost) > ap.avg_cost;

-- Разделить заказы на категории по времени доставки: утро (6-12), день (12-18), вечер (18-24), ночь (0-6)
SELECT o.*,
       CASE
           WHEN EXTRACT(HOUR FROM o.timestamp) BETWEEN 6 AND 11 THEN 'morning'
           WHEN EXTRACT(HOUR FROM o.timestamp) BETWEEN 12 AND 17 THEN 'afternoon'
           WHEN EXTRACT(HOUR FROM o.timestamp) BETWEEN 18 AND 23 THEN 'evening'
           ELSE 'night'
       END as delivery_time_category
FROM orders o
ORDER BY o.timestamp;
