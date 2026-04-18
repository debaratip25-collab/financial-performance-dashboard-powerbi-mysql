CREATE DATABASE financial_dashboard;
USE financial_dashboard;

CREATE TABLE dim_date (
    date_id DATE PRIMARY KEY,
    month VARCHAR(10),
    quarter VARCHAR(5),
    year INT
);

CREATE TABLE dim_region (
    region_id INT PRIMARY KEY,
    region_name VARCHAR(50)
);

CREATE TABLE dim_department (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(50)
);

CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    product_category VARCHAR(50)
);

CREATE TABLE dim_channel (
    channel_id INT PRIMARY KEY,
    channel_name VARCHAR(50)
);

CREATE TABLE dim_segment (
    segment_id INT PRIMARY KEY,
    segment_name VARCHAR(50)
);

CREATE TABLE fact_revenue (
    revenue_id INT AUTO_INCREMENT PRIMARY KEY,
    date_id DATE,
    region_id INT,
    product_id INT,
    channel_id INT,
    segment_id INT,
    sales_volume INT,
    revenue DECIMAL(12,2),

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (region_id) REFERENCES dim_region(region_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (channel_id) REFERENCES dim_channel(channel_id),
    FOREIGN KEY (segment_id) REFERENCES dim_segment(segment_id)
);

CREATE TABLE fact_expenses (
    expense_id INT AUTO_INCREMENT PRIMARY KEY,
    date_id DATE,
    department_id INT,
    cogs DECIMAL(12,2),
    operating_expenses DECIMAL(12,2),

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (department_id) REFERENCES dim_department(department_id)
);

CREATE TABLE fact_budget (
    budget_id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT,
    budgeted_revenue DECIMAL(12,2),
    budgeted_expenses DECIMAL(12,2),

    FOREIGN KEY (department_id) REFERENCES dim_department(department_id)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_date.csv'
INTO TABLE dim_date
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(date_id, month, quarter, year);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_region.csv'
INTO TABLE dim_region
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(region_id, region_name);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_department.csv'
INTO TABLE dim_department
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(department_id, department_name);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_product.csv'
INTO TABLE dim_product
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_name, product_category);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_channel.csv'
INTO TABLE dim_channel
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(channel_id, channel_name);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_segment.csv'
INTO TABLE dim_segment
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(segment_id, segment_name);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_budget.csv'
INTO TABLE fact_budget
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(department_id, @department_name, budgeted_revenue, budgeted_expenses);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_expenses.csv'
INTO TABLE fact_expenses
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(date_id, department_id, cogs, operating_expenses);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_revenue.csv'
INTO TABLE fact_revenue
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(date_id, region_id, product_id, channel_id, segment_id, sales_volume, revenue);

CREATE TABLE fact_operating_expenses (
    expense_id INT AUTO_INCREMENT PRIMARY KEY,
    date_id DATE,
    department_id INT,
    operating_expenses DECIMAL(12,2),
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (department_id) REFERENCES dim_department(department_id)
);

RENAME TABLE fact_expenses TO fact_expenses_old;

CREATE TABLE fact_expenses (
    expense_id INT AUTO_INCREMENT PRIMARY KEY,
    date_id DATE,
    region_id INT,
    product_id INT,
    department_id INT,
    cogs DECIMAL(12,2),
    operating_expenses DECIMAL(12,2),

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (region_id) REFERENCES dim_region(region_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (department_id) REFERENCES dim_department(department_id)
);

INSERT INTO fact_expenses
(date_id, region_id, product_id, department_id, cogs, operating_expenses)

SELECT
r.date_id,
r.region_id,
r.product_id,
1 AS department_id,

ROUND(r.revenue * 0.62,2) AS cogs,
ROUND(r.revenue * 0.18,2) AS operating_expenses

FROM fact_revenue r;

CREATE OR REPLACE VIEW vw_financial_master AS

SELECT
r.date_id,
r.region_id,
r.product_id,

r.total_revenue,
r.total_volume,

e.total_cogs,
e.total_opex,

(r.total_revenue - e.total_cogs) AS gross_profit,

(r.total_revenue - e.total_cogs - e.total_opex) AS net_profit,

ROUND(
((r.total_revenue - e.total_cogs - e.total_opex)
/ NULLIF(r.total_revenue,0))*100,
2
) AS profit_margin_pct

FROM
(
SELECT
date_id,
region_id,
product_id,
SUM(revenue) AS total_revenue,
SUM(sales_volume) AS total_volume
FROM fact_revenue
GROUP BY date_id, region_id, product_id
) r

JOIN
(
SELECT
date_id,
region_id,
product_id,
SUM(cogs) AS total_cogs,
SUM(operating_expenses) AS total_opex
FROM fact_expenses
GROUP BY date_id, region_id, product_id
) e

ON r.date_id = e.date_id
AND r.region_id = e.region_id
AND r.product_id = e.product_id;

