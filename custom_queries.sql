-- Найти всех поставщиков определенного товара и вывести о поставщиках инфо
SELECT s.*
FROM suppliers s
INNER JOIN commodities c
    ON c.supplier_id = s.id
WHERE c.name = 'Vinegar ''Peasant''';

-- Найти все заказы сделанные за последний месяц и вывести по ним инфу
SELECT *
FROM orders
WHERE timestamp > (current_timestamp - interval '1 month')
ORDER BY timestamp;

-- Найти клиента который заказал на максимальную сумму за все время (без учета скидок)
WITH max_order_cost AS (
    SELECT
        o.user_id,
        SUM(COALESCE(d.cost, 0) + COALESCE(c.cost, 0)) as total_spent
    FROM orders o
        LEFT JOIN orders_composition compos ON o.id = compos.order_id
        LEFT JOIN dishes d ON compos.dish_id = d.id
        LEFT JOIN commodities c ON compos.commodity_id = c.id
    GROUP BY o.user_id
    ORDER BY total_spent DESC
    LIMIT 1
)
SELECT
    u.*,
    mx.total_spent
FROM users u
    JOIN max_order_cost mx ON u.id = mx.user_id
WHERE mx.total_spent = mx.total_spent
LIMIT 1;

-- Найти все блюда в составе которого есть определенный ингредиент
SELECT * FROM dishes
WHERE ingredients LIKE '%Coconut milk%';

--------------------------------------------------------------------------------

-- Найти заведение из которого было заказано больше всего блюд за все время
SELECT
    d.supplier_id AS supplier_id,
    COUNT(oc.dish_id) AS total_dishes_ordered
FROM
    orders_composition oc
JOIN
    dishes d
ON
    oc.dish_id = d.id
GROUP BY
    d.supplier_id
ORDER BY
    total_dishes_ordered DESC
LIMIT 1;

-- Найти все блюда которые были заказаны с определенной даты по какую-то дату и вывести инфо о заказе с этим блюдом
SELECT
    d.id AS dish_id,
    d.name AS dish_name,
    d.cost AS dish_cost,
    o.id AS order_id,
    o.timestamp AS order_date,
    o.source_address,
    o.target_address,
    o.status AS order_status,
    o.payment_id
FROM
    orders o
JOIN
    orders_composition oc
ON
    o.id = oc.order_id
JOIN
    dishes d
ON
    oc.dish_id = d.id
WHERE
    o.timestamp BETWEEN '2024-11-01 00:00:00' AND '2024-11-27 23:59:59';

-- Найти всех клиентов у которых фамилия начинается на определенную букву
SELECT
    *
FROM
    users u
WHERE
    u.surname LIKE 'A%';

--------------------------------------------------------------------------------
