-- =============================================================
--  FOOD DELIVERY — SAMPLE DATA (SEED)
--  Author  : Lohit Sai
--  Engine  : MySQL 8.0+
-- =============================================================

USE food_delivery;

-- -------------------------------------------------------------
-- CUISINES
-- -------------------------------------------------------------
INSERT INTO cuisines (cuisine_name) VALUES
    ('North Indian'), ('South Indian'), ('Chinese'),
    ('Italian'), ('Fast Food'), ('Biryani'),
    ('Desserts'), ('Beverages'), ('Healthy');

-- -------------------------------------------------------------
-- CUSTOMERS
-- -------------------------------------------------------------
INSERT INTO customers (full_name, email, phone, password_hash) VALUES
    ('Arjun Mehta',    'arjun.mehta@email.com',   '9876543210', SHA2('pass123', 256)),
    ('Priya Sharma',   'priya.sharma@email.com',   '9876543211', SHA2('pass123', 256)),
    ('Rahul Nair',     'rahul.nair@email.com',     '9876543212', SHA2('pass123', 256)),
    ('Sneha Reddy',    'sneha.reddy@email.com',    '9876543213', SHA2('pass123', 256)),
    ('Vikram Patel',   'vikram.patel@email.com',   '9876543214', SHA2('pass123', 256));

-- -------------------------------------------------------------
-- CUSTOMER ADDRESSES
-- -------------------------------------------------------------
INSERT INTO customer_addresses (customer_id, label, address_line1, city, state, pincode, latitude, longitude, is_default) VALUES
    (1, 'Home',  '12 MG Road, Banjara Hills',    'Hyderabad', 'Telangana', '500034', 17.4126, 78.4425, 1),
    (2, 'Home',  '45 Jubilee Hills, Road No. 36','Hyderabad', 'Telangana', '500033', 17.4311, 78.4081, 1),
    (3, 'Work',  'Cyber Towers, Hi-Tech City',   'Hyderabad', 'Telangana', '500081', 17.4472, 78.3762, 1),
    (4, 'Home',  '8 Kondapur Main Rd',           'Hyderabad', 'Telangana', '500084', 17.4580, 78.3547, 1),
    (5, 'Home',  '22 Madhapur, Phase 2',         'Hyderabad', 'Telangana', '500081', 17.4501, 78.3920, 1);

-- -------------------------------------------------------------
-- RESTAURANTS
-- -------------------------------------------------------------
INSERT INTO restaurants (name, owner_name, email, phone, address_line1, city, state, pincode, latitude, longitude, opening_time, closing_time, commission_pct) VALUES
    ('Spice Garden',      'Ravi Kumar',   'spice@email.com',     '8001001001', 'Plot 5, Banjara Hills',     'Hyderabad', 'Telangana', '500034', 17.4121, 78.4430, '09:00:00', '23:00:00', 15.00),
    ('Dragon Palace',     'Lin Wei',      'dragon@email.com',    '8001001002', '22 Jubilee Hills',          'Hyderabad', 'Telangana', '500033', 17.4320, 78.4090, '11:00:00', '23:30:00', 18.00),
    ('Pizza Hub',         'Marco Rossi',  'pizza@email.com',     '8001001003', 'Cyber Towers Block A',      'Hyderabad', 'Telangana', '500081', 17.4478, 78.3770, '10:00:00', '23:00:00', 20.00),
    ('Biryani Express',   'Saleem Khan',  'biryani@email.com',   '8001001004', '67 Kondapur Main Rd',       'Hyderabad', 'Telangana', '500084', 17.4590, 78.3550, '11:00:00', '22:00:00', 15.00),
    ('Green Bowl',        'Ananya Iyer',  'greenbowl@email.com', '8001001005', '3 Madhapur, HUDA Layout',   'Hyderabad', 'Telangana', '500081', 17.4510, 78.3925, '08:00:00', '22:00:00', 12.00);

-- Restaurant-Cuisine mappings
INSERT INTO restaurant_cuisines (restaurant_id, cuisine_id) VALUES
    (1,1),(1,2),(1,6),   -- Spice Garden: North Indian, South Indian, Biryani
    (2,3),               -- Dragon Palace: Chinese
    (3,4),(3,5),         -- Pizza Hub: Italian, Fast Food
    (4,6),(4,1),         -- Biryani Express: Biryani, North Indian
    (5,9),(5,8);         -- Green Bowl: Healthy, Beverages

-- -------------------------------------------------------------
-- MENU CATEGORIES
-- -------------------------------------------------------------
INSERT INTO menu_categories (restaurant_id, category_name, display_order) VALUES
    (1,'Starters',1),(1,'Main Course',2),(1,'Biryani',3),(1,'Desserts',4),
    (2,'Soups',1),(2,'Noodles & Rice',2),(2,'Manchurian',3),
    (3,'Pizzas',1),(3,'Pasta',2),(3,'Sides',3),
    (4,'Biryani',1),(4,'Kebabs',2),(4,'Breads',3),
    (5,'Bowls',1),(5,'Salads',2),(5,'Juices',3);

-- -------------------------------------------------------------
-- MENU ITEMS
-- -------------------------------------------------------------
INSERT INTO menu_items (restaurant_id, category_id, item_name, price, is_veg, prep_time_min) VALUES
    -- Spice Garden
    (1,1,'Paneer Tikka',        220.00, 1, 15),
    (1,1,'Chicken 65',          280.00, 0, 18),
    (1,2,'Butter Chicken',      320.00, 0, 20),
    (1,2,'Dal Makhani',         240.00, 1, 20),
    (1,3,'Hyderabadi Biryani',  380.00, 0, 35),
    (1,3,'Veg Biryani',         280.00, 1, 30),
    -- Dragon Palace
    (2,5,'Hot & Sour Soup',     160.00, 1, 10),
    (2,6,'Hakka Noodles',       200.00, 1, 15),
    (2,6,'Fried Rice',          190.00, 0, 15),
    (2,7,'Veg Manchurian',      220.00, 1, 15),
    -- Pizza Hub
    (3,8,'Margherita Pizza',    350.00, 1, 20),
    (3,8,'Chicken Pepperoni',   450.00, 0, 22),
    (3,9,'Arrabbiata Pasta',    280.00, 1, 15),
    (3,10,'Garlic Bread',       120.00, 1,  8),
    -- Biryani Express
    (4,11,'Mutton Biryani',     420.00, 0, 40),
    (4,11,'Chicken Biryani',    350.00, 0, 35),
    (4,12,'Seekh Kebab',        300.00, 0, 20),
    (4,13,'Butter Naan',         60.00, 1, 10),
    -- Green Bowl
    (5,14,'Quinoa Power Bowl',  340.00, 1, 12),
    (5,15,'Greek Salad',        260.00, 1, 10),
    (5,16,'Fresh Lime Soda',     80.00, 1,  5);

-- -------------------------------------------------------------
-- DELIVERY AGENTS
-- -------------------------------------------------------------
INSERT INTO delivery_agents (full_name, phone, vehicle_type, vehicle_number) VALUES
    ('Karthik Reddy',  '7001001001', 'bike',    'TS09AB1234'),
    ('Suresh Kumar',   '7001001002', 'scooter', 'TS10CD5678'),
    ('Mohan Das',      '7001001003', 'bike',    'TS11EF9012'),
    ('Raju Singh',     '7001001004', 'bicycle', NULL),
    ('Ganesh Babu',    '7001001005', 'bike',    'TS12GH3456');

-- -------------------------------------------------------------
-- COUPONS
-- -------------------------------------------------------------
INSERT INTO coupons (code, discount_type, discount_value, min_order_value, max_discount, usage_limit, valid_from, valid_until) VALUES
    ('WELCOME50',  'flat',       50.00,  200.00, NULL,  1000, '2024-01-01', '2024-12-31'),
    ('SAVE20',     'percentage', 20.00,  300.00, 100.00, 500, '2024-01-01', '2024-12-31'),
    ('FREEDEL',    'flat',       30.00,  150.00, NULL,  2000, '2024-01-01', '2024-06-30'),
    ('BIRYANI10',  'percentage', 10.00,  350.00,  50.00,  200, '2024-01-01', '2024-12-31');

-- -------------------------------------------------------------
-- ORDERS + ORDER ITEMS + PAYMENTS (10 sample orders)
-- -------------------------------------------------------------
INSERT INTO orders (customer_id, restaurant_id, agent_id, delivery_address_id, order_status, subtotal, delivery_fee, discount_amount, tax_amount, total_amount, placed_at, delivered_at) VALUES
    (1, 1, 1, 1, 'delivered', 600.00, 30.00,  50.00, 30.00,  610.00, '2024-03-01 12:30:00', '2024-03-01 13:15:00'),
    (2, 2, 2, 2, 'delivered', 390.00, 30.00,   0.00, 19.50,  439.50, '2024-03-02 13:00:00', '2024-03-02 13:50:00'),
    (3, 3, 3, 3, 'delivered', 800.00, 30.00,  80.00, 40.00,  790.00, '2024-03-03 19:15:00', '2024-03-03 20:05:00'),
    (4, 4, 4, 4, 'delivered', 770.00, 30.00,   0.00, 38.50,  838.50, '2024-03-04 20:00:00', '2024-03-04 20:55:00'),
    (5, 5, 5, 5, 'delivered', 600.00, 30.00,  50.00, 30.00,  610.00, '2024-03-05 09:30:00', '2024-03-05 10:10:00'),
    (1, 4, 1, 1, 'delivered', 770.00, 30.00,  77.00, 38.50,  761.50, '2024-03-10 13:00:00', '2024-03-10 14:00:00'),
    (2, 1, 2, 2, 'delivered', 560.00, 30.00,   0.00, 28.00,  618.00, '2024-03-12 19:30:00', '2024-03-12 20:20:00'),
    (3, 5, 3, 3, 'delivered', 420.00, 30.00,   0.00, 21.00,  471.00, '2024-03-15 10:00:00', '2024-03-15 10:45:00'),
    (4, 3, 4, 4, 'cancelled', 450.00, 30.00,   0.00, 22.50,  502.50, '2024-03-18 18:00:00', NULL),
    (5, 2, 5, 5, 'delivered', 380.00, 30.00,   0.00, 19.00,  429.00, '2024-03-20 14:30:00', '2024-03-20 15:20:00');

INSERT INTO order_items (order_id, item_id, quantity, unit_price, item_total) VALUES
    (1,  1, 1, 220.00, 220.00),(1,  3, 1, 320.00, 320.00),(1,  6, 1,  60.00,  60.00),
    (2,  8, 1, 200.00, 200.00),(2,  9, 1, 190.00, 190.00),
    (3, 11, 1, 350.00, 350.00),(3, 12, 1, 450.00, 450.00),
    (4, 15, 1, 420.00, 420.00),(4, 17, 1, 300.00, 300.00),(4, 18, 2,  60.00, 120.00),
    (5, 19, 1, 340.00, 340.00),(5, 20, 1, 260.00, 260.00),
    (6, 15, 1, 420.00, 420.00),(6, 16, 1, 350.00, 350.00),
    (7,  5, 1, 380.00, 380.00),(7,  4, 1, 240.00, 240.00),
    (8, 19, 1, 340.00, 340.00),(8, 21, 1,  80.00,  80.00),
    (9, 11, 1, 350.00, 350.00),(9, 14, 1, 120.00, 120.00),
    (10, 7, 1, 160.00, 160.00),(10, 8, 1, 200.00, 200.00);

INSERT INTO payments (order_id, payment_method, payment_status, transaction_ref, amount, paid_at) VALUES
    (1,  'upi',        'success', 'UPI20240301001', 610.00,  '2024-03-01 12:31:00'),
    (2,  'card',       'success', 'CARD20240302001',439.50,  '2024-03-02 13:01:00'),
    (3,  'upi',        'success', 'UPI20240303001', 790.00,  '2024-03-03 19:16:00'),
    (4,  'cod',        'success', NULL,             838.50,  '2024-03-04 20:55:00'),
    (5,  'wallet',     'success', 'WAL20240305001', 610.00,  '2024-03-05 09:31:00'),
    (6,  'upi',        'success', 'UPI20240310001', 761.50,  '2024-03-10 13:01:00'),
    (7,  'netbanking', 'success', 'NB20240312001',  618.00,  '2024-03-12 19:31:00'),
    (8,  'card',       'success', 'CARD20240315001',471.00,  '2024-03-15 10:01:00'),
    (9,  'upi',        'refunded','UPI20240318001', 502.50,  '2024-03-18 18:01:00'),
    (10, 'cod',        'success', NULL,             429.00,  '2024-03-20 15:20:00');

INSERT INTO reviews (order_id, customer_id, restaurant_id, agent_id, food_rating, delivery_rating, review_text) VALUES
    (1,  1, 1, 1, 5, 4, 'Paneer tikka was excellent! Quick delivery.'),
    (2,  2, 2, 2, 4, 5, 'Noodles were fresh. Agent was very punctual.'),
    (3,  3, 3, 3, 5, 4, 'Best pizza in Hyderabad. Will order again!'),
    (4,  4, 4, 4, 5, 3, 'Mutton biryani was amazing. Delivery took a bit long.'),
    (5,  5, 5, 5, 4, 5, 'Healthy food with great taste. Fast delivery!'),
    (6,  1, 4, 1, 4, 4, 'Good biryani. Consistent quality.'),
    (7,  2, 1, 2, 5, 5, 'Dal makhani was superb. Will definitely order again!'),
    (8,  3, 5, 3, 4, 4, 'Love the quinoa bowl. Very fresh ingredients.'),
    (10, 5, 2, 5, 3, 4, 'Soup was okay, expected more flavour.');
