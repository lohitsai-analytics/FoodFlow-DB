-- =============================================================
--  FOOD DELIVERY APPLICATION — DATABASE SCHEMA
--  Author  : Lohit Sai
--  Engine  : MySQL 8.0+
--  Version : 1.0
-- =============================================================
--  Modules covered:
--    1. Customer & Authentication ✅
--    2. Restaurant & Menu Management ✅
--    3. Customer Ordering ✅
--    4. Delivery Tracking ✅
--    5. Payments & Invoicing ✅
-- =============================================================

CREATE DATABASE IF NOT EXISTS food_delivery
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE food_delivery;

-- -------------------------------------------------------------
-- MODULE 1 — CUSTOMERS
-- -------------------------------------------------------------

CREATE TABLE customers (
    customer_id     INT             UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(100)    NOT NULL,
    email           VARCHAR(150)    NOT NULL UNIQUE,
    phone           VARCHAR(15)     NOT NULL UNIQUE,
    password_hash   VARCHAR(255)    NOT NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                                    ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE customer_addresses (
    address_id      INT             UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id     INT             UNSIGNED NOT NULL,
    label           VARCHAR(50)     NOT NULL,               -- 'Home', 'Work', etc.
    address_line1   VARCHAR(200)    NOT NULL,
    address_line2   VARCHAR(200),
    city            VARCHAR(100)    NOT NULL,
    state           VARCHAR(100)    NOT NULL,
    pincode         VARCHAR(10)     NOT NULL,
    latitude        DECIMAL(10,8),
    longitude       DECIMAL(11,8),
    is_default      TINYINT(1)      NOT NULL DEFAULT 0,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ca_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE
);

-- -------------------------------------------------------------
-- MODULE 2 — RESTAURANTS & MENU MANAGEMENT
-- -------------------------------------------------------------

CREATE TABLE cuisines (
    cuisine_id      TINYINT         UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cuisine_name    VARCHAR(80)     NOT NULL UNIQUE
);

CREATE TABLE restaurants (
    restaurant_id   INT             UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150)    NOT NULL,
    owner_name      VARCHAR(100)    NOT NULL,
    email           VARCHAR(150)    NOT NULL UNIQUE,
    phone           VARCHAR(15)     NOT NULL,
    address_line1   VARCHAR(200)    NOT NULL,
    city            VARCHAR(100)    NOT NULL,
    state           VARCHAR(100)    NOT NULL,
    pincode         VARCHAR(10)     NOT NULL,
    latitude        DECIMAL(10,8),
    longitude       DECIMAL(11,8),
    avg_rating      DECIMAL(3,2)    NOT NULL DEFAULT 0.00,
    total_ratings   INT             UNSIGNED NOT NULL DEFAULT 0,
    opening_time    TIME            NOT NULL,
    closing_time    TIME            NOT NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    commission_pct  DECIMAL(5,2)    NOT NULL DEFAULT 15.00, -- platform commission %
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                                    ON UPDATE CURRENT_TIMESTAMP
);

-- Many-to-many: a restaurant can serve multiple cuisines
CREATE TABLE restaurant_cuisines (
    restaurant_id   INT             UNSIGNED NOT NULL,
    cuisine_id      TINYINT         UNSIGNED NOT NULL,
    PRIMARY KEY (restaurant_id, cuisine_id),
    CONSTRAINT fk_rc_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_rc_cuisine
        FOREIGN KEY (cuisine_id) REFERENCES cuisines(cuisine_id)
);

CREATE TABLE menu_categories (
    category_id     INT             UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    restaurant_id   INT             UNSIGNED NOT NULL,
    category_name   VARCHAR(100)    NOT NULL,
    display_order   TINYINT         UNSIGNED NOT NULL DEFAULT 0,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,

    CONSTRAINT fk_mc_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
        ON DELETE CASCADE
);


CREATE TABLE menu_items (
    item_id         INT             UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    restaurant_id   INT             UNSIGNED NOT NULL,
    category_id     INT             UNSIGNED NOT NULL,
    item_name       VARCHAR(150)    NOT NULL,
    description     TEXT,
    price           DECIMAL(10,2)   NOT NULL,
    is_veg          TINYINT(1)      NOT NULL DEFAULT 0,
    is_available    TINYINT(1)      NOT NULL DEFAULT 1,
    prep_time_min   TINYINT         UNSIGNED NOT NULL DEFAULT 20,  -- avg prep in minutes
    image_url       VARCHAR(500),
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                                    ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_mi_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_mi_category
        FOREIGN KEY (category_id) REFERENCES menu_categories(category_id)
);

-- -------------------------------------------------------------
-- MODULE 3 — ORDERING
-- -------------------------------------------------------------

CREATE TABLE delivery_agents (
    agent_id        INT             UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(100)    NOT NULL,
    phone           VARCHAR(15)     NOT NULL UNIQUE,
    vehicle_type    ENUM('bike','bicycle','scooter')  NOT NULL DEFAULT 'bike', 
    vehicle_number  VARCHAR(20),
    avg_rating      DECIMAL(3,2)    NOT NULL DEFAULT 0.00,
    is_available    TINYINT(1)      NOT NULL DEFAULT 1,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    order_id            INT             UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id         INT             UNSIGNED NOT NULL,
    restaurant_id       INT             UNSIGNED NOT NULL,
    agent_id            INT             UNSIGNED,               -- assigned after placement
    delivery_address_id INT             UNSIGNED NOT NULL,
    order_status        ENUM(
                            'placed',
                            'confirmed',
                            'preparing',
                            'ready_for_pickup',
                            'out_for_delivery',
                            'delivered',
                            'cancelled'
                        ) NOT NULL DEFAULT 'placed',
    subtotal            DECIMAL(10,2)   NOT NULL,
    delivery_fee        DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    discount_amount     DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    tax_amount          DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    total_amount        DECIMAL(10,2)   NOT NULL,
    special_instructions TEXT,
    estimated_delivery  DATETIME,
    placed_at           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    delivered_at        DATETIME,

    CONSTRAINT fk_ord_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_ord_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
    CONSTRAINT fk_ord_agent
        FOREIGN KEY (agent_id) REFERENCES delivery_agents(agent_id),
    CONSTRAINT fk_ord_address 
        FOREIGN KEY (delivery_address_id) REFERENCES customer_addresses(address_id)
);

CREATE TABLE order_items (
    order_item_id   INT             UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id        INT             UNSIGNED NOT NULL,
    item_id         INT             UNSIGNED NOT NULL,
    quantity        TINYINT         UNSIGNED NOT NULL DEFAULT 1,
    unit_price      DECIMAL(10,2)   NOT NULL,   -- price snapshot at order time
    item_total      DECIMAL(10,2)   NOT NULL,   -- quantity * unit_price

    CONSTRAINT fk_oi_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_oi_item
        FOREIGN KEY (item_id) REFERENCES menu_items(item_id)
);

CREATE TABLE coupons (
    coupon_id       INT             UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code            VARCHAR(30)     NOT NULL UNIQUE,
    discount_type   ENUM('flat','percentage')   NOT NULL,
    discount_value  DECIMAL(10,2)   NOT NULL,
    min_order_value DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    max_discount    DECIMAL(10,2),                          -- cap for percentage type
    usage_limit     INT             UNSIGNED,               -- NULL = unlimited
    used_count      INT             UNSIGNED NOT NULL DEFAULT 0,
    valid_from      DATE            NOT NULL,
    valid_until     DATE            NOT NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1
);

CREATE TABLE order_coupons (
    order_id        INT             UNSIGNED NOT NULL,
    coupon_id       INT             UNSIGNED NOT NULL,
    discount_applied DECIMAL(10,2)  NOT NULL,
    PRIMARY KEY (order_id, coupon_id),
    CONSTRAINT fk_oc_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_oc_coupon
        FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id)
);

-- -------------------------------------------------------------
-- MODULE 4 — DELIVERY TRACKING
-- -------------------------------------------------------------

CREATE TABLE order_status_log (
    log_id          INT             UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id        INT             UNSIGNED NOT NULL,
    status          ENUM(
                        'placed','confirmed','preparing',
                        'ready_for_pickup','out_for_delivery',
                        'delivered','cancelled'
                    ) NOT NULL,
    changed_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note            VARCHAR(255),

    CONSTRAINT fk_osl_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON DELETE CASCADE
);

CREATE TABLE agent_locations (
    location_id     BIGINT          UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    agent_id        INT             UNSIGNED NOT NULL,
    order_id        INT             UNSIGNED,
    latitude        DECIMAL(10,8)   NOT NULL,
    longitude       DECIMAL(11,8)   NOT NULL,
    recorded_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_al_agent
        FOREIGN KEY (agent_id) REFERENCES delivery_agents(agent_id),
    CONSTRAINT fk_al_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- -------------------------------------------------------------
-- MODULE 5 — PAYMENTS & INVOICING
-- -------------------------------------------------------------

CREATE TABLE payments (
    payment_id          INT             UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id            INT             UNSIGNED NOT NULL UNIQUE,
    payment_method      ENUM('upi','card','netbanking','cod','wallet')
                                        NOT NULL,
    payment_status      ENUM('pending','success','failed','refunded')
                                        NOT NULL DEFAULT 'pending',
    transaction_ref     VARCHAR(100)    UNIQUE,             -- gateway reference
    amount              DECIMAL(10,2)   NOT NULL,
    paid_at             DATETIME,
    refund_amount       DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    refunded_at         DATETIME,

    CONSTRAINT fk_pay_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE invoices (
    invoice_id          INT             UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id            INT             UNSIGNED NOT NULL UNIQUE,
    invoice_number      VARCHAR(30)     NOT NULL UNIQUE,    -- e.g. INV-2024-000001
    subtotal            DECIMAL(10,2)   NOT NULL,
    tax_amount          DECIMAL(10,2)   NOT NULL,
    delivery_fee        DECIMAL(10,2)   NOT NULL,
    discount_amount     DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    grand_total         DECIMAL(10,2)   NOT NULL,
    issued_at           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_inv_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- -------------------------------------------------------------
-- REVIEWS
-- -------------------------------------------------------------

CREATE TABLE reviews (
    review_id       INT             UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id        INT             UNSIGNED NOT NULL UNIQUE,
    customer_id     INT             UNSIGNED NOT NULL,
    restaurant_id   INT             UNSIGNED NOT NULL,
    agent_id        INT             UNSIGNED,
    food_rating     TINYINT         UNSIGNED NOT NULL CHECK (food_rating BETWEEN 1 AND 5),
    delivery_rating TINYINT         UNSIGNED CHECK (delivery_rating BETWEEN 1 AND 5),
    review_text     TEXT,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_rev_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_rev_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_rev_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
    CONSTRAINT fk_rev_agent
        FOREIGN KEY (agent_id) REFERENCES delivery_agents(agent_id)
);

-- =============================================================
--  INDEXES — for query performance on high-traffic columns
-- =============================================================

CREATE INDEX idx_orders_customer      ON orders(customer_id);
CREATE INDEX idx_orders_restaurant    ON orders(restaurant_id);
CREATE INDEX idx_orders_agent         ON orders(agent_id);
CREATE INDEX idx_orders_status        ON orders(order_status);
CREATE INDEX idx_orders_placed_at     ON orders(placed_at);
CREATE INDEX idx_order_items_order    ON order_items(order_id);
CREATE INDEX idx_menu_items_rest      ON menu_items(restaurant_id);
CREATE INDEX idx_menu_items_category  ON menu_items(category_id);
CREATE INDEX idx_payments_status      ON payments(payment_status);
CREATE INDEX idx_reviews_restaurant   ON reviews(restaurant_id);
CREATE INDEX idx_agent_loc_agent      ON agent_locations(agent_id, recorded_at);
CREATE INDEX idx_status_log_order     ON order_status_log(order_id);


