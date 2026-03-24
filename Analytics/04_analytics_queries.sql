-- =============================================================
--  FOOD DELIVERY — ANALYTICS QUERIES
--  Author  : Lohit Sai
--  Engine  : MySQL 8.0+
--  Purpose : Business intelligence queries for analyst portfolio
-- =============================================================

USE food_delivery;

-- =============================================================
--  SECTION A : REVENUE ANALYTICS
-- =============================================================

-- -------------------------------------------------------------
-- Q1 : Monthly revenue trend with MoM growth %
-- -------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(placed_at, '%Y-%m')     AS month,
        SUM(total_amount)                   AS revenue,
        COUNT(*)                            AS total_orders,
        SUM(CASE WHEN order_status = 'cancelled'
                 THEN 1 ELSE 0 END)         AS cancelled_orders
    FROM orders
    GROUP BY DATE_FORMAT(placed_at, '%Y-%m')
)
SELECT
    month,
    ROUND(revenue, 2)                       AS revenue,
    total_orders,
    cancelled_orders,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month) * 100, 2
    )                                       AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;


-- -------------------------------------------------------------
-- Q2 : Revenue by restaurant — with platform commission earned
-- -------------------------------------------------------------
SELECT
    r.restaurant_id,
    r.name                                  AS restaurant_name,
    COUNT(DISTINCT o.order_id)              AS total_orders,
    ROUND(SUM(o.total_amount), 2)           AS gross_revenue,
    ROUND(SUM(o.total_amount)
          * r.commission_pct / 100, 2)      AS platform_commission,
    ROUND(AVG(o.total_amount), 2)           AS avg_order_value,
    ROUND(r.avg_rating, 2)                  AS avg_rating
FROM restaurants r
JOIN orders o ON r.restaurant_id = o.restaurant_id
WHERE o.order_status = 'delivered'
GROUP BY r.restaurant_id, r.name, r.commission_pct, r.avg_rating
ORDER BY gross_revenue DESC;


-- -------------------------------------------------------------
-- Q3 : Pareto analysis — top restaurants driving 80% revenue
-- -------------------------------------------------------------
WITH rest_revenue AS (
    SELECT
        r.name,
        ROUND(SUM(o.total_amount), 2) AS revenue
    FROM orders o
    JOIN restaurants r USING (restaurant_id)
    WHERE o.order_status = 'delivered'
    GROUP BY r.restaurant_id, r.name
),
ranked AS (
    SELECT
        name,
        revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC)   AS running_total,
        SUM(revenue) OVER ()                         AS grand_total
    FROM rest_revenue
)
SELECT
    name,
    revenue,
    ROUND(revenue / grand_total * 100, 2)           AS revenue_share_pct,
    ROUND(running_total / grand_total * 100, 2)     AS cumulative_pct
FROM ranked
ORDER BY revenue DESC;


-- -------------------------------------------------------------
-- Q4 : Revenue by payment method
-- -------------------------------------------------------------
SELECT
    p.payment_method,
    COUNT(*)                            AS transactions,
    ROUND(SUM(p.amount), 2)             AS total_revenue,
    ROUND(AVG(p.amount), 2)             AS avg_transaction_value,
    ROUND(SUM(p.amount) /
        (SELECT SUM(amount) FROM payments WHERE payment_status = 'success')
        * 100, 2)                       AS revenue_share_pct
FROM payments p
WHERE p.payment_status = 'success'
GROUP BY p.payment_method
ORDER BY total_revenue DESC;


-- =============================================================
--  SECTION B : CUSTOMER BEHAVIOUR ANALYTICS
-- =============================================================

-- -------------------------------------------------------------
-- Q5 : Customer segmentation — one-time vs repeat buyers
-- -------------------------------------------------------------
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(order_id)             AS order_count,
        ROUND(SUM(total_amount), 2) AS lifetime_value,
        MIN(placed_at)              AS first_order,
        MAX(placed_at)              AS last_order
    FROM orders
    WHERE order_status = 'delivered'
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN order_count = 1  THEN 'One-time buyer'
        WHEN order_count <= 3 THEN 'Occasional (2–3 orders)'
        ELSE                       'Loyal (4+ orders)'
    END                                     AS segment,
    COUNT(*)                                AS customer_count,
    ROUND(AVG(lifetime_value), 2)           AS avg_ltv,
    ROUND(AVG(order_count), 1)              AS avg_orders,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM customer_orders), 2
    )                                       AS pct_of_customers
FROM customer_orders
GROUP BY segment
ORDER BY avg_ltv DESC;


-- -------------------------------------------------------------
-- Q6 : Repeat purchase gap — days between 1st and 2nd order
-- -------------------------------------------------------------
WITH ranked_orders AS (
    SELECT
        customer_id,
        placed_at,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY placed_at) AS rn
    FROM orders
    WHERE order_status = 'delivered'
),
first_second AS (
    SELECT
        a.customer_id,
        DATEDIFF(b.placed_at, a.placed_at) AS days_to_return
    FROM ranked_orders a
    JOIN ranked_orders b
      ON a.customer_id = b.customer_id
     AND a.rn = 1 AND b.rn = 2
)
SELECT
    ROUND(AVG(days_to_return), 1)       AS avg_days_to_return,
    MIN(days_to_return)                 AS min_days,
    MAX(days_to_return)                 AS max_days,
    COUNT(*)                            AS repeat_customers
FROM first_second;


-- -------------------------------------------------------------
-- Q7 : Top 5 customers by lifetime value
-- -------------------------------------------------------------
SELECT
    c.customer_id,
    c.full_name,
    c.email,
    COUNT(o.order_id)               AS total_orders,
    ROUND(SUM(o.total_amount), 2)   AS lifetime_value,
    ROUND(AVG(o.total_amount), 2)   AS avg_order_value,
    MAX(o.placed_at)                AS last_order_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_id, c.full_name, c.email
ORDER BY lifetime_value DESC
LIMIT 5;


-- =============================================================
--  SECTION C : DELIVERY & OPERATIONS ANALYTICS
-- =============================================================

-- -------------------------------------------------------------
-- Q8 : On-time vs delayed delivery analysis
-- -------------------------------------------------------------
SELECT
    CASE
        WHEN delivered_at <= estimated_delivery THEN 'On-time'
        ELSE 'Delayed'
    END                                     AS delivery_status,
    COUNT(*)                                AS orders,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE,
        placed_at, delivered_at)), 1)       AS avg_delivery_min,
    ROUND(AVG(r.food_rating), 2)            AS avg_food_rating,
    ROUND(AVG(r.delivery_rating), 2)        AS avg_delivery_rating
FROM orders o
LEFT JOIN reviews r USING (order_id)
WHERE o.order_status = 'delivered'
  AND o.estimated_delivery IS NOT NULL
  AND o.delivered_at IS NOT NULL
GROUP BY delivery_status;


-- -------------------------------------------------------------
-- Q9 : Agent performance leaderboard
-- -------------------------------------------------------------
SELECT
    da.agent_id,
    da.full_name,
    da.vehicle_type,
    COUNT(o.order_id)                       AS total_deliveries,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE,
        o.placed_at, o.delivered_at)), 1)   AS avg_delivery_min,
    ROUND(da.avg_rating, 2)                 AS avg_rating,
    SUM(CASE WHEN o.delivered_at > o.estimated_delivery
             THEN 1 ELSE 0 END)             AS late_deliveries,
    ROUND(
        SUM(CASE WHEN o.delivered_at <= o.estimated_delivery
                 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    )                                       AS on_time_pct
FROM delivery_agents da
JOIN orders o ON da.agent_id = o.agent_id
WHERE o.order_status = 'delivered'
  AND o.delivered_at IS NOT NULL
GROUP BY da.agent_id, da.full_name, da.vehicle_type, da.avg_rating
ORDER BY avg_rating DESC, on_time_pct DESC;


-- -------------------------------------------------------------
-- Q10 : Order status funnel — conversion from placed to delivered
-- -------------------------------------------------------------
SELECT
    order_status,
    COUNT(*)                                AS orders,
    ROUND(COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM orders), 2)  AS pct_of_total
FROM orders
GROUP BY order_status
ORDER BY FIELD(order_status,
    'placed','confirmed','preparing',
    'ready_for_pickup','out_for_delivery',
    'delivered','cancelled');


-- =============================================================
--  SECTION D : MENU & PRODUCT ANALYTICS
-- =============================================================

-- -------------------------------------------------------------
-- Q11 : Top 10 best-selling items by revenue
-- -------------------------------------------------------------
SELECT
    mi.item_id,
    mi.item_name,
    r.name                                  AS restaurant,
    SUM(oi.quantity)                        AS total_qty_sold,
    ROUND(SUM(oi.item_total), 2)            AS total_revenue,
    ROUND(AVG(oi.unit_price), 2)            AS avg_unit_price,
    IF(mi.is_veg = 1, 'Veg', 'Non-Veg')    AS type
FROM order_items oi
JOIN menu_items mi USING (item_id)
JOIN restaurants r ON mi.restaurant_id = r.restaurant_id
JOIN orders o USING (order_id)
WHERE o.order_status = 'delivered'
GROUP BY mi.item_id, mi.item_name, r.name, mi.is_veg
ORDER BY total_revenue DESC
LIMIT 10;


-- -------------------------------------------------------------
-- Q12 : Veg vs Non-Veg order split
-- -------------------------------------------------------------
WITH order_type AS (
    SELECT
        o.order_id,
        CASE WHEN SUM(mi.is_veg) = COUNT(*) THEN 'Full Veg'
             WHEN SUM(mi.is_veg) = 0         THEN 'Full Non-Veg'
             ELSE 'Mixed'
        END AS order_type
    FROM order_items oi
    JOIN menu_items mi USING (item_id)
    JOIN orders o USING (order_id)
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
)
SELECT
    order_type,
    COUNT(*)                                AS orders,
    ROUND(COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM order_type), 2) AS pct
FROM order_type
GROUP BY order_type
ORDER BY orders DESC;


-- =============================================================
--  SECTION E : FINANCIAL & COUPON ANALYTICS
-- =============================================================

-- -------------------------------------------------------------
-- Q13 : Coupon effectiveness analysis
-- -------------------------------------------------------------
SELECT
    c.code,
    c.discount_type,
    c.discount_value,
    COUNT(oc.order_id)                      AS times_used,
    ROUND(SUM(oc.discount_applied), 2)      AS total_discount_given,
    ROUND(SUM(o.total_amount), 2)           AS revenue_generated,
    ROUND(AVG(o.total_amount), 2)           AS avg_order_value_with_coupon,
    ROUND(
        SUM(oc.discount_applied) /
        NULLIF(SUM(o.total_amount + oc.discount_applied), 0) * 100
    , 2)                                    AS discount_to_gross_pct
FROM coupons c
JOIN order_coupons oc USING (coupon_id)
JOIN orders o USING (order_id)
WHERE o.order_status = 'delivered'
GROUP BY c.coupon_id, c.code, c.discount_type, c.discount_value
ORDER BY revenue_generated DESC;


-- -------------------------------------------------------------
-- Q14 : Refund & cancellation impact
-- -------------------------------------------------------------
SELECT
    COUNT(*)                                AS cancelled_orders,
    ROUND(SUM(p.amount), 2)                 AS revenue_at_risk,
    ROUND(SUM(p.refund_amount), 2)          AS total_refunded,
    ROUND(AVG(p.amount), 2)                 AS avg_cancelled_order_value,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM orders), 2
    )                                       AS cancellation_rate_pct
FROM orders o
JOIN payments p USING (order_id)
WHERE o.order_status = 'cancelled';


-- =============================================================
--  SECTION F : VIEWS (reusable for Power BI / reporting)
-- =============================================================

-- -------------------------------------------------------------
-- VIEW : Order summary flat table (Power BI ready)
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
    o.order_id,
    o.placed_at,
    DATE_FORMAT(o.placed_at, '%Y-%m')       AS order_month,
    c.full_name                             AS customer_name,
    c.email                                 AS customer_email,
    r.name                                  AS restaurant_name,
    r.city,
    da.full_name                            AS agent_name,
    o.order_status,
    o.subtotal,
    o.delivery_fee,
    o.discount_amount,
    o.tax_amount,
    o.total_amount,
    p.payment_method,
    p.payment_status,
    TIMESTAMPDIFF(MINUTE,
        o.placed_at, o.delivered_at)        AS delivery_duration_min,
    CASE WHEN o.delivered_at <= o.estimated_delivery
         THEN 'On-time' ELSE 'Delayed'
    END                                     AS delivery_flag,
    rev.food_rating,
    rev.delivery_rating
FROM orders o
JOIN customers c         ON o.customer_id     = c.customer_id
JOIN restaurants r       ON o.restaurant_id   = r.restaurant_id
LEFT JOIN delivery_agents da ON o.agent_id    = da.agent_id
LEFT JOIN payments p     ON o.order_id        = p.order_id
LEFT JOIN reviews rev    ON o.order_id        = rev.order_id;


-- -------------------------------------------------------------
-- VIEW : Daily KPI snapshot
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW vw_daily_kpi AS
SELECT
    DATE(placed_at)                         AS order_date,
    COUNT(*)                                AS total_orders,
    SUM(CASE WHEN order_status = 'delivered'  THEN 1 ELSE 0 END) AS delivered,
    SUM(CASE WHEN order_status = 'cancelled'  THEN 1 ELSE 0 END) AS cancelled,
    ROUND(SUM(CASE WHEN order_status = 'delivered'
                   THEN total_amount ELSE 0 END), 2)             AS daily_revenue,
    ROUND(AVG(CASE WHEN order_status = 'delivered'
                   THEN total_amount END), 2)                     AS avg_order_value,
    COUNT(DISTINCT customer_id)             AS unique_customers
FROM orders
GROUP BY DATE(placed_at)
ORDER BY order_date;

select * from vw_daily_kpi;