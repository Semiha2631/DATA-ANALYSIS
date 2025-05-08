
---2. assigment 1.question
	

SELECT 
    DISTINCT C1.customer_id,
    C1.first_name,
    C1.last_name,
    CASE 
        WHEN C2.customer_id IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS other_product
FROM sale.customer C1
JOIN sale.orders O1 ON C1.customer_id = O1.customer_id
JOIN sale.order_item OI1 ON O1.order_id = OI1.order_id
JOIN product.product P1 ON OI1.product_id = P1.product_id
LEFT JOIN (
    SELECT DISTINCT C2.customer_id
    FROM sale.customer C2
    JOIN sale.orders O2 ON C2.customer_id = O2.customer_id
    JOIN sale.order_item OI2 ON O2.order_id = OI2.order_id
    JOIN product.product P2 ON OI2.product_id = P2.product_id
    WHERE P2.product_name = 'Polk Audio - 50 W Woofer - Black'
) AS C2 ON C1.customer_id = C2.customer_id
WHERE P1.product_name = '2TB Red 5400 rpm SATA III 3.5 Internal NAS HDD';


2.Assigment 2.question

WITH advertising_actions (Visitor_ID, Adv_Type, Action) AS (
    SELECT 1, 'A', 'Left' UNION ALL
    SELECT 2, 'A', 'Order' UNION ALL
    SELECT 3, 'B', 'Left' UNION ALL
    SELECT 4, 'A', 'Order' UNION ALL
    SELECT 5, 'A', 'Review' UNION ALL
    SELECT 6, 'A', 'Left' UNION ALL
    SELECT 7, 'B', 'Left' UNION ALL
    SELECT 8, 'B', 'Order' UNION ALL
    SELECT 9, 'B', 'Review' UNION ALL
    SELECT 10, 'A', 'Review'
)
SELECT 
    Adv_Type,
    COUNT(CASE WHEN Action = 'Order' THEN 1 END) * 1.0 / COUNT(*) AS conversion_rate
FROM advertising_actions
GROUP BY Adv_Type;