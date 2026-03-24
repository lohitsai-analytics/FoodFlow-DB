# 🍽️ FoodFlow-DB — Production-Grade Food Delivery Database System

A **fully normalized, transaction-safe relational database system (MySQL 8.0)** designed to support a scalable food delivery platform.

This project models the **complete lifecycle of an order-driven marketplace**, including customer onboarding, restaurant operations, order processing, delivery tracking, payments, and post-order analytics.

Unlike basic academic projects, this system implements **database-level business logic (triggers, stored procedures, audit logs, and analytical queries)** to simulate real-world production behavior.

---

# 📷 Entity Relationship Diagram

![ERD](Docs/erd_diagram.png)

📎 Interactive ERD: 

---

# 🧠 System Scope

The database supports end-to-end operations:

* Customer & address management
* Restaurant & dynamic menu system
* Order lifecycle management
* Delivery agent assignment & tracking
* Payment processing & invoicing
* Review & rating system
* Business analytics queries

This is not just a schema — it is a **complete transactional system with embedded business logic**.

---

# 🏗 Data Architecture

### Design Standard

* Fully normalized to **3rd Normal Form (3NF)**
* Eliminates redundancy
* Ensures referential integrity
* Optimized for both **OLTP and analytical workloads**

---

### Schema Scale

* **16 relational tables**
* Strong PK–FK enforcement
* Junction tables for many-to-many relationships
* Time-series tracking for logistics

---

### Core Design Decisions

**1. Financial Snapshot Modeling**

All monetary values (subtotal, tax, discount, total) are stored at order time.

→ Prevents historical inconsistencies when prices or tax rules change

---

**2. Materialized Aggregates**

* `restaurants.avg_rating`
* `delivery_agents.avg_rating`

Maintained via triggers instead of runtime aggregation

→ Eliminates expensive `AVG()` queries on large datasets

---

**3. Audit Logging (Immutable History)**

`order_status_log` captures every status transition automatically via trigger

→ Enables full lifecycle reconstruction and SLA analysis

---

**4. Time-Series Tracking**

`agent_locations` stores continuous GPS logs using **BIGINT PK**

→ Designed for high-frequency insert workloads

---

# ⚙️ Database Logic (Beyond CRUD)

## 🔁 Triggers (6 implemented)

Key automations:

* Auto-log order status transitions
* Auto-generate invoices on delivery
* Auto-update restaurant & agent ratings
* Auto-track coupon usage
* Auto-set delivery timestamps

These eliminate dependency on application logic and ensure **data consistency at the database layer**. 

---

## ⚡ Stored Procedures

### `sp_place_order`

* Validates restaurant availability
* Applies coupon logic
* Calculates tax, discount, total
* Inserts order + payment + logs (transaction-safe)

---

### `sp_update_order_status`

* Validates state transitions
* Updates order lifecycle
* Writes audit logs automatically

---

### Key Insight

Business rules are enforced **inside the database**, not the UI layer.

→ Prevents inconsistent states in distributed systems

---

# 📊 Analytical Layer (SQL for BI)

Advanced SQL queries implemented for business insights: 

### Revenue Analytics

* Monthly revenue with MoM growth
* Revenue by restaurant with commission
* Pareto analysis (top 80% contributors)
* Revenue by payment method

---

### Customer Analytics

* Customer segmentation (one-time vs repeat)
* Lifetime value (LTV)
* Repeat purchase gap analysis

---

### Operations Analytics

* On-time vs delayed delivery impact
* Agent performance leaderboard
* Order funnel conversion rates

---

### Product Analytics

* Top-selling items
* Veg vs non-veg order distribution

---

# 📦 Data Initialization

Includes realistic seed data for:

* Customers
* Restaurants
* Menus
* Orders
* Coupons
* Delivery agents

Enables immediate testing of:

* Transactions
* Queries
* Business scenarios



---

# 📈 What This Project Demonstrates

### Data Engineering

* Relational modeling at scale
* Constraint design (PK, FK, UNIQUE)
* Transaction-safe operations
* Schema normalization (3NF)

---

### Backend System Thinking

* Business logic inside DB (not UI)
* Event-driven triggers
* Stored procedure orchestration
* Audit & traceability design

---

### Data Analytics

* Window functions (LAG, ROW_NUMBER)
* Cohort & segmentation analysis
* Revenue modeling
* Operational KPI tracking

---

# ⚠️ Gaps (Intentional / Realistic)

This is important — real engineers mention limitations:

* No partitioning for large-scale datasets
* No role-based access control
* No API/application integration layer
* No caching (Redis)

---

# 🚀 Potential Improvements

* Add indexing strategy for high-volume queries
* Partition `orders` & `agent_locations` tables
* Introduce event streaming (Kafka)
* Build REST API layer
* Integrate with Power BI / Tableau

---

# 📂 Project Structure

```
FoodFlow-DB
│
├── Docs/
│   └── erd_diagram.png
│
├── 01_schema.sql
├── 02_triggers_procedures_.sql
├── 03_seed_data.sql
├── 04_analytics_queries.sql
│
└── README.md
```

---

# 👨‍💻 Author

**Lohit Sai**

Final Year Computer Science Student
Focused on Data Analytics, Data Engineering, and Business Intelligence

---

# ⭐ Evaluation Summary

This project demonstrates:

✔ Strong database design fundamentals
✔ Understanding of real-world system architecture
✔ Ability to implement business logic at DB level
✔ Capability to write analytical SQL for decision-making

---
