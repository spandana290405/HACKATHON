-- Step 1:- Load raw data
-- 1) cust
create table Customers
(
 customer_id text,
 first_name char(50),
 last_name char(50),
 email text,
 join_date date
);

copy Customers
FROM 'C:\Users\routh\OneDrive\Desktop\cust.csv'
DELIMITER ','
CSV HEADER;

select * from Customers

-- 2) prod

create table Products
(
 product_id text,
 product_name char(50),
 category char(50),
 price numeric
);

copy Products
FROM 'C:\Users\routh\OneDrive\Desktop\products.csv'
DELIMITER ','
CSV HEADER;

-- 3) Saless


create table Saless
(
 sale_id text,
 sale_date date, 
 customer_id text,
 store_id text,
 total_amount numeric
);

copy Saless
FROM 'C:\Users\routh\OneDrive\Desktop\sales.csv'
DELIMITER ','
CSV HEADER;

-- 4) sales_items


create table sales_items
(
 sale_item_id text,
 sale_id text, 
 product_id text,
 quantity numeric,
 unit_price numeric
);

copy sales_items
FROM 'C:\Users\routh\OneDrive\Desktop\sales_items.csv'
DELIMITER ','
CSV HEADER;

-- 5) store


create table store
(
 store_id text,
 store_name text,        
 city char(50)
);

copy store
FROM 'C:\Users\routh\OneDrive\Desktop\stores.csv'
DELIMITER ','
CSV HEADER;



-- 6) loyalty

create table loyalty
(
 rule_id text,
 rule_name char(50),       
 points_per_currency numeric,
 min_spend numeric,
 bonus_points numeric
);

copy loyalty
FROM 'C:\Users\routh\OneDrive\Desktop\loyalty.csv'
DELIMITER ','
CSV HEADER;

-- Step 2:- Data quality checks

SELECT *
FROM saless
WHERE customer_id IS NULL
   OR sale_date IS NULL
   OR total_amount IS NULL;

SELECT customer_id, COUNT(*)
FROM Customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT *
FROM sales
WHERE total_amount <= 0;


-- Step 3:- Loyalty points calculation 

-- next step loyalty points calculation

ALTER TABLE Customers
ADD COLUMN IF NOT EXISTS total_loyalty_points INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_purchase_date DATE;

select * from Customers

-- calculation

CREATE OR REPLACE VIEW sale_loyalty_points AS
SELECT
    s.sale_id,
    s.customer_id,
    s.sale_date,
    s.total_amount,
    (
        (s.total_amount * r.points_per_currency) +
        CASE
            WHEN s.total_amount >= r.min_spend
            THEN r.bonus_points
            ELSE 0
        END
    )::INT AS points_earned
FROM sales s
CROSS JOIN loyalty r;

-- update customer loyalty totals

UPDATE Customers c
SET total_loyalty_points = sub.total_points,
    last_purchase_date = sub.last_purchase
FROM (
    SELECT
        customer_id,
        SUM(points_earned) AS total_points,
        MAX(sale_date) AS last_purchase
    FROM sale_loyalty_points
    GROUP BY customer_id
) sub
WHERE c.customer_id = sub.customer_id;

-- validation 

SELECT customer_id, total_loyalty_points, last_purchase_date
FROM Customers
ORDER BY total_loyalty_points DESC
LIMIT 5;
-- returned 0
-- fixing errors


select * from loyalty

DROP VIEW IF EXISTS sale_loyalty_points;

CREATE VIEW sale_loyalty_points AS
SELECT
    s.sale_id,
    s.customer_id,
    s.sale_date,
    s.total_amount,

    -- Base points
    (s.total_amount * 1)::INT
    +
    -- Highest applicable bonus
    COALESCE(
        (
            SELECT MAX(l.bonus_points)
            FROM loyalty l
            WHERE s.total_amount >= l.min_spend
        ),
        0
    ) AS points_earned

FROM sales s;

SELECT * FROM sale_loyalty_points LIMIT 10;

-- returned 0

UPDATE customers c
SET
    total_loyalty_points = sub.total_points,
    last_purchase_date = sub.last_purchase
FROM (
    SELECT
        customer_id,
        SUM(points_earned) AS total_points,
        MAX(sale_date) AS last_purchase
    FROM sale_loyalty_points
    GROUP BY customer_id
) sub
WHERE c.customer_id = sub.customer_id;


SELECT customer_id, total_loyalty_points, last_purchase_date
FROM Customers
ORDER BY total_loyalty_points DESC
LIMIT 5;
-- returned 0



-- Finalised Loyalty Points calculation after fixing errors
DROP VIEW IF EXISTS sale_loyalty_points;

-- Calculation
CREATE VIEW sale_loyalty_points AS
SELECT
    s.sale_id,
    s.customer_id,
    s.sale_date,
    s.total_amount,

    -- Base points + highest applicable bonus
    (s.total_amount * 1)::INT
    +
    COALESCE(
        (
            SELECT MAX(l.bonus_points)
            FROM loyalty l
            WHERE s.total_amount >= l.min_spend
        ),
        0
    ) AS points_earned

FROM saless s;

--check

SELECT * FROM sale_loyalty_points ;


-- updating Customers table


UPDATE Customers c
SET
    total_loyalty_points = sub.total_points,
    last_purchase_date = sub.last_purchase
FROM (
    SELECT
        customer_id,
        SUM(points_earned) AS total_points,
        MAX(sale_date) AS last_purchase
    FROM sale_loyalty_points
    GROUP BY customer_id
) sub
WHERE c.customer_id = sub.customer_id;

-- final validation 

SELECT customer_id, total_loyalty_points, last_purchase_date
FROM customers
ORDER BY total_loyalty_points DESC
LIMIT 5;


-- Step 4:- Computing RFM metrics
-- Creating RFM model 

CREATE TABLE customer_rfm AS
SELECT
    c.customer_id,

    -- Recency: days since last purchase
     (CURRENT_DATE - c.last_purchase_date) AS recency,

    -- Frequency: number of purchases
    COUNT(s.sale_id) AS frequency,

    -- Monetary: total spend
     SUM(s.total_amount) AS monetary,

    -- Loyalty overlay
    c.total_loyalty_points
FROM Customers c
LEFT JOIN saless s
    ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.last_purchase_date, c.total_loyalty_points;

SELECT * FROM customer_rfm LIMIT 5;


-- Step 5:- Customer Segmentation
-- Finding High_spenders and At_Risk customers


CREATE TEMP TABLE high_spenders AS
SELECT customer_id
FROM customer_rfm
ORDER BY monetary DESC
LIMIT (
    SELECT CEIL(COUNT(*) * 0.10)
    FROM customer_rfm
);


CREATE TEMP TABLE at_risk_customers AS
SELECT customer_id
FROM customer_rfm
WHERE recency > 30
  AND total_loyalty_points > 0;

CREATE TABLE customer_segments (
    segment_id INTEGER PRIMARY KEY,
    segment_name TEXT
);

INSERT INTO customer_segments (segment_id, segment_name)
VALUES
    (1, 'High-Spender'),
    (2, 'At-Risk');

SELECT * FROM customer_segments;

INSERT INTO customer_segments (segment_id, segment_name)
VALUES
    (1, 'High-Spender'),
    (2, 'At-Risk')
ON CONFLICT DO NOTHING;

ALTER TABLE customers
ADD COLUMN segment_id INTEGER;

UPDATE Customers
SET segment_id = 1
WHERE customer_id IN (
    SELECT customer_id FROM high_spenders
);

UPDATE Customers
SET segment_id = 2
WHERE customer_id IN (
    SELECT customer_id FROM at_risk_customers
)
AND segment_id IS NULL;


ALTER TABLE customers
ADD COLUMN segment_name char(50);


UPDATE Customers
SET segment_name = 'High_spender'
WHERE customer_id IN (
    SELECT customer_id FROM high_spenders
);

UPDATE Customers
SET segment_name = 'At-Risk'
WHERE customer_id IN (
    SELECT customer_id FROM at_risk_customers
)
AND segment_id = 2;

SELECT
    cs.segment_name,
    COUNT(*) AS customer_count
FROM Customers c
JOIN customer_segments cs
  ON c.segment_id = cs.segment_id
GROUP BY cs.segment_name;


select * from customers

