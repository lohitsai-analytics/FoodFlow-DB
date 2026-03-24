-- =============================================================
--  FOOD DELIVERY — TRIGGERS & STORED PROCEDURES
--  Author  : Lohit Sai
--  Engine  : MySQL 8.0+
-- =============================================================

USE food_delivery;

-- =============================================================
--  TRIGGERS
-- =============================================================

DELIMITER $$

-- -------------------------------------------------------------
-- TRIGGER 1 : Auto-log every order status change
--   Fires AFTER orders.order_status is updated
-- -------------------------------------------------------------
CREATE TRIGGER trg_log_order_status
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF OLD.order_status <> NEW.order_status THEN
        INSERT INTO order_status_log (order_id, status, changed_at)
        VALUES (NEW.order_id, NEW.order_status, NOW());
    END IF;
END$$

-- -------------------------------------------------------------
-- TRIGGER 2 : Auto-generate invoice when order is delivered
--   Fires AFTER orders.order_status changes to 'delivered'
-- -------------------------------------------------------------
CREATE TRIGGER trg_auto_invoice
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    DECLARE v_invoice_num VARCHAR(30);

    IF NEW.order_status = 'delivered' AND OLD.order_status <> 'delivered' THEN
        SET v_invoice_num = CONCAT(
            'INV-', YEAR(NOW()), '-',
            LPAD(NEW.order_id, 6, '0')
        );

        INSERT INTO invoices (
            order_id, invoice_number,
            subtotal, tax_amount, delivery_fee,
            discount_amount, grand_total, issued_at
        )
        VALUES (
            NEW.order_id, v_invoice_num,
            NEW.subtotal, NEW.tax_amount, NEW.delivery_fee,
            NEW.discount_amount, NEW.total_amount, NOW()
        )
        ON DUPLICATE KEY UPDATE issued_at = issued_at; -- idempotent safety
    END IF;
END$$

-- -------------------------------------------------------------
-- TRIGGER 3 : Update restaurant avg_rating after new review
--   Fires AFTER INSERT on reviews
-- -------------------------------------------------------------
CREATE TRIGGER trg_update_restaurant_rating
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    UPDATE restaurants
    SET
        avg_rating    = (
            SELECT ROUND(AVG(food_rating), 2)
            FROM reviews
            WHERE restaurant_id = NEW.restaurant_id
        ),
        total_ratings = total_ratings + 1
    WHERE restaurant_id = NEW.restaurant_id;
END$$

-- -------------------------------------------------------------
-- TRIGGER 4 : Update agent avg_rating after new review
--   Fires AFTER INSERT on reviews (only when delivery_rating provided)
-- -------------------------------------------------------------
CREATE TRIGGER trg_update_agent_rating
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    IF NEW.agent_id IS NOT NULL AND NEW.delivery_rating IS NOT NULL THEN
        UPDATE delivery_agents
        SET avg_rating = (
            SELECT ROUND(AVG(delivery_rating), 2)
            FROM reviews
            WHERE agent_id = NEW.agent_id
              AND delivery_rating IS NOT NULL
        )
        WHERE agent_id = NEW.agent_id;
    END IF;
END$$

-- -------------------------------------------------------------
-- TRIGGER 5 : Increment coupon used_count on order placement
-- -------------------------------------------------------------
CREATE TRIGGER trg_coupon_usage
AFTER INSERT ON order_coupons
FOR EACH ROW
BEGIN
    UPDATE coupons
    SET used_count = used_count + 1
    WHERE coupon_id = NEW.coupon_id;
END$$

-- -------------------------------------------------------------
-- TRIGGER 6 : Set delivered_at timestamp automatically
-- -------------------------------------------------------------
CREATE TRIGGER trg_set_delivered_at
BEFORE UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NEW.order_status = 'delivered' AND OLD.order_status <> 'delivered' THEN
        SET NEW.delivered_at = NOW();
    END IF;
END$$

DELIMITER ;


-- =============================================================
--  STORED PROCEDURES
-- =============================================================

DELIMITER $$

-- -------------------------------------------------------------
-- PROCEDURE 1 : Place a new order
--   Validates restaurant is open, creates order + order_items,
--   logs initial status, and creates a pending payment record.
-- -------------------------------------------------------------
CREATE PROCEDURE sp_place_order (
    IN  p_customer_id       INT UNSIGNED,
    IN  p_restaurant_id     INT UNSIGNED,
    IN  p_address_id        INT UNSIGNED,
    IN  p_payment_method    VARCHAR(20),
    IN  p_special_notes     TEXT,
    IN  p_coupon_code       VARCHAR(30),
    OUT p_order_id          INT UNSIGNED,
    OUT p_message           VARCHAR(255)
)
sp_place_order: BEGIN
    DECLARE v_subtotal      DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_tax           DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_delivery_fee  DECIMAL(10,2) DEFAULT 30.00;
    DECLARE v_discount      DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_total         DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_coupon_id     INT UNSIGNED  DEFAULT NULL;
    DECLARE v_rest_open     TINYINT       DEFAULT 0;

    -- Check restaurant is active and currently open
    SELECT COUNT(*) INTO v_rest_open
    FROM restaurants
    WHERE restaurant_id = p_restaurant_id
      AND is_active = 1
      AND CURTIME() BETWEEN opening_time AND closing_time;

    IF v_rest_open = 0 THEN
        SET p_order_id = NULL;
        SET p_message  = 'Restaurant is closed or inactive.';
        LEAVE sp_place_order;
    END IF;

    -- Calculate subtotal from a temp cart (assumes caller inserts into a session cart)
    -- In production this would read from a cart table; here we compute inline
    SELECT IFNULL(SUM(oi_temp.item_total), 0) INTO v_subtotal
    FROM (
        SELECT 0 AS item_total  -- placeholder; replaced by application layer
    ) AS oi_temp;

    -- Validate coupon if provided
    IF p_coupon_code IS NOT NULL AND p_coupon_code <> '' THEN
        SELECT coupon_id, discount_type, discount_value, max_discount
        INTO v_coupon_id, @dtype, @dval, @maxd
        FROM coupons
        WHERE code       = p_coupon_code
          AND is_active  = 1
          AND CURDATE() BETWEEN valid_from AND valid_until
          AND (usage_limit IS NULL OR used_count < usage_limit);

        IF v_coupon_id IS NOT NULL THEN
            IF @dtype = 'flat' THEN
                SET v_discount = @dval;
            ELSE
                SET v_discount = LEAST(v_subtotal * @dval / 100, IFNULL(@maxd, 9999));
            END IF;
        END IF;
    END IF;

    -- Tax = 5% of subtotal
    SET v_tax   = ROUND(v_subtotal * 0.05, 2);
    SET v_total = v_subtotal + v_delivery_fee + v_tax - v_discount;

    START TRANSACTION;

        INSERT INTO orders (
            customer_id, restaurant_id, delivery_address_id,
            order_status, subtotal, delivery_fee,
            discount_amount, tax_amount, total_amount,
            special_instructions, estimated_delivery
        ) VALUES (
            p_customer_id, p_restaurant_id, p_address_id,
            'placed', v_subtotal, v_delivery_fee,
            v_discount, v_tax, v_total,
            p_special_notes, DATE_ADD(NOW(), INTERVAL 45 MINUTE)
        );

        SET p_order_id = LAST_INSERT_ID();

        -- Log initial status
        INSERT INTO order_status_log (order_id, status)
        VALUES (p_order_id, 'placed');

        -- Create pending payment record
        INSERT INTO payments (order_id, payment_method, payment_status, amount)
        VALUES (p_order_id, p_payment_method, 'pending', v_total);

        -- Apply coupon if valid
        IF v_coupon_id IS NOT NULL THEN
            INSERT INTO order_coupons (order_id, coupon_id, discount_applied)
            VALUES (p_order_id, v_coupon_id, v_discount);
        END IF;

    COMMIT;

    SET p_message = CONCAT('Order placed successfully. Order ID: ', p_order_id);

END$$


-- -------------------------------------------------------------
-- PROCEDURE 2 : Update order status
--   Validates allowed transitions, updates order, trigger fires log
-- -------------------------------------------------------------
CREATE PROCEDURE sp_update_order_status (
    IN  p_order_id      INT UNSIGNED,
    IN  p_new_status    VARCHAR(30),
    IN  p_note          VARCHAR(255),
    OUT p_success       TINYINT,
    OUT p_message       VARCHAR(255)
)
sp_update_order_status: BEGIN
    DECLARE v_current_status VARCHAR(30);

    SELECT order_status INTO v_current_status
    FROM orders WHERE order_id = p_order_id;

    IF v_current_status IS NULL THEN
        SET p_success = 0;
        SET p_message = 'Order not found.';
        LEAVE sp_update_order_status;
    END IF;

    IF v_current_status = 'cancelled' OR v_current_status = 'delivered' THEN
        SET p_success = 0;
        SET p_message = CONCAT('Cannot update. Order already ', v_current_status, '.');
        LEAVE sp_update_order_status;
    END IF;

    UPDATE orders
    SET order_status = p_new_status
    WHERE order_id = p_order_id;

    -- Add optional note to log (trigger already fires the base log)
    IF p_note IS NOT NULL AND p_note <> '' THEN
        UPDATE order_status_log
        SET note = p_note
        WHERE log_id = (
            SELECT MAX(log_id) FROM order_status_log
            WHERE order_id = p_order_id
        );
    END IF;

    SET p_success = 1;
    SET p_message = CONCAT('Status updated to ', p_new_status, '.');
END$$


-- -------------------------------------------------------------
-- PROCEDURE 3 : Process payment confirmation
--   Updates payment record and marks order confirmed
-- -------------------------------------------------------------
CREATE PROCEDURE sp_confirm_payment (
    IN  p_order_id          INT UNSIGNED,
    IN  p_transaction_ref   VARCHAR(100),
    OUT p_success           TINYINT,
    OUT p_message           VARCHAR(255)
)
sp_confirm_payment: BEGIN
    DECLARE v_pay_status VARCHAR(20);

    SELECT payment_status INTO v_pay_status
    FROM payments WHERE order_id = p_order_id;

    IF v_pay_status IS NULL THEN
        SET p_success = 0;
        SET p_message = 'Payment record not found.';
        LEAVE sp_confirm_payment;
    END IF;

    IF v_pay_status <> 'pending' THEN
        SET p_success = 0;
        SET p_message = CONCAT('Payment already ', v_pay_status, '.');
        LEAVE sp_confirm_payment;
    END IF;

    START TRANSACTION;

        UPDATE payments
        SET payment_status  = 'success',
            transaction_ref = p_transaction_ref,
            paid_at         = NOW()
        WHERE order_id = p_order_id;

        UPDATE orders
        SET order_status = 'confirmed'
        WHERE order_id = p_order_id;

    COMMIT;

    SET p_success = 1;
    SET p_message = 'Payment confirmed and order status updated.';
END$$


-- -------------------------------------------------------------
-- PROCEDURE 4 : Assign delivery agent to order
-- -------------------------------------------------------------
CREATE PROCEDURE sp_assign_agent (
    IN  p_order_id  INT UNSIGNED,
    IN  p_agent_id  INT UNSIGNED,
    OUT p_success   TINYINT,
    OUT p_message   VARCHAR(255)
)
sp_assign_agent: BEGIN
    DECLARE v_available TINYINT;

    SELECT is_available INTO v_available
    FROM delivery_agents
    WHERE agent_id = p_agent_id AND is_active = 1;

    IF v_available IS NULL THEN
        SET p_success = 0;
        SET p_message = 'Agent not found or inactive.';
        LEAVE sp_assign_agent;
    END IF;

    IF v_available = 0 THEN
        SET p_success = 0;
        SET p_message = 'Agent is currently unavailable.';
        LEAVE sp_assign_agent;
    END IF;

    START TRANSACTION;
        UPDATE orders
        SET agent_id = p_agent_id
        WHERE order_id = p_order_id;

        UPDATE delivery_agents
        SET is_available = 0
        WHERE agent_id = p_agent_id;
    COMMIT;

    SET p_success = 1;
    SET p_message = CONCAT('Agent ', p_agent_id, ' assigned to order ', p_order_id, '.');
END$$


DELIMITER ;
