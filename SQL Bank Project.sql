create database bank;
use bank;

CREATE TABLE Regions (
    region_id INT PRIMARY KEY,
    region_name VARCHAR(50)
);

INSERT INTO Regions (region_id, region_name)
VALUES
    (1, 'North America'),
    (2, 'Europe'),
    (3, 'Asia'),
    (4, 'Australia'),
    (5, 'Africa');

	select * from Regions;

	--customer_Nodes table

CREATE TABLE Customer_Nodes (
    customer_id INT PRIMARY KEY,
    node_id INT,
    region_id INT,
    allocation_date DATE,
    FOREIGN KEY (region_id) REFERENCES Regions(region_id)
);

INSERT INTO Customer_Nodes (customer_id, node_id, region_id, allocation_date)
VALUES
    (101, 1, 3, '2024-11-01'),
    (102, 2, 4, '2024-11-02'),
    (103, 3, 2, '2024-11-03'),
    (104, 4, 1, '2024-11-04'),
    (105, 5, 3, '2024-11-05'),
    (106, 1, 3, '2024-11-06'),
    (107, 2, 4, '2024-11-07'),
    (108, 3, 2, '2024-11-08'),
    (109, 4, 1, '2024-11-09'),
    (110, 5, 5, '2024-11-10');

	select * from Customer_Nodes;

-- Customer Transaction

CREATE TABLE Customer_Transactions (
    transaction_id INT PRIMARY KEY,
    customer_id INT,
    transaction_type VARCHAR(50),
    transaction_amount DECIMAL(10, 2),
    transaction_date DATE,
    FOREIGN KEY (customer_id) REFERENCES Customer_Nodes(customer_id)
);

INSERT INTO Customer_Transactions (transaction_id, customer_id, transaction_type, transaction_amount, transaction_date)
VALUES
    (201, 101, 'Deposit', 500.00, '2024-11-01'),
    (202, 102, 'Withdrawal', 200.00, '2024-11-02'),
    (203, 103, 'Purchase', 150.00, '2024-11-03'),
    (204, 104, 'Deposit', 700.00, '2024-11-04'),
    (205, 105, 'Withdrawal', 300.00, '2024-11-05'),
    (206, 106, 'Deposit', 400.00, '2024-11-06'),
    (207, 107, 'Purchase', 100.00, '2024-11-07'),
    (208, 108, 'Withdrawal', 250.00, '2024-11-08'),
    (209, 109, 'Deposit', 600.00, '2024-11-09'),
    (210, 110, 'Purchase', 200.00, '2024-11-10');

select * from Customer_Transactions;

----Query----

--Question 1: Q1: How many unique nodes are there on the Data Bank system?
select COUNT(DISTINCT node_id) AS unique_nodes FROM Customer_Nodes;

-- Question 2. What is the total transaction amount per type?
select transaction_type, Sum(transaction_amount) AS total_amount
from Customer_Transactions
GROUP BY transaction_type;

--Question 3. How many customers are allocated to each region?

select r.region_name, Count(c.customer_id) AS customer_count
FROM Customer_Nodes c
join Regions r on c.region_id = r.region_id
Group by r.region_name;

-- How many days on average are customers reallocated to a different node?

WITH ReallocationDays AS (
    SELECT 
        customer_id,
        DATEDIFF(DAY, allocation_date, LEAD(allocation_date) OVER (PARTITION BY customer_id ORDER BY allocation_date)) AS reallocation_days
    FROM Customer_Nodes
)
SELECT AVG(reallocation_days) AS avg_reallocation_days
FROM ReallocationDays
WHERE reallocation_days IS NOT NULL; -- Exclude NULL values from the calculation

--Q: What is the unique count and total amount for each transaction type?

SELECT transaction_type, 
       COUNT(transaction_id) AS unique_count, 
       SUM(transaction_amount) AS total_amount
FROM Customer_Transactions
GROUP BY transaction_type;

--What is the average total historical deposit counts and amounts for all customers?

SELECT AVG(deposit_count) AS avg_deposit_count, 
       AVG(deposit_amount) AS avg_deposit_amount
FROM (
    SELECT customer_id, 
           COUNT(CASE WHEN transaction_type = 'Deposit' THEN 1 END) AS deposit_count,
           SUM(CASE WHEN transaction_type = 'Deposit' THEN transaction_amount ELSE 0 END) AS deposit_amount
    FROM Customer_Transactions
    GROUP BY customer_id
) subquery;

--For each month, how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

SELECT MONTH(transaction_date) AS month, 
       COUNT(DISTINCT customer_id) AS customer_count
FROM Customer_Transactions
WHERE transaction_type = 'Deposit' AND 
      customer_id IN (
          SELECT customer_id
          FROM Customer_Transactions
          WHERE transaction_type IN ('Purchase', 'Withdrawal')
      )
GROUP BY MONTH(transaction_date);

--: What is the closing balance for each customer at the end of the month?

SELECT customer_id, 
       MONTH(transaction_date) AS month, 
       SUM(CASE 
               WHEN transaction_type = 'Deposit' THEN transaction_amount 
               WHEN transaction_type IN ('Withdrawal', 'Purchase') THEN -transaction_amount 
               ELSE 0 
           END) AS closing_balance
FROM Customer_Transactions
GROUP BY customer_id, MONTH(transaction_date);

--Data allocated based on the amount of money at the end of the previous month

SELECT customer_id, 
       MONTH(transaction_date) AS month, 
       SUM(CASE 
               WHEN transaction_type = 'Deposit' THEN transaction_amount 
               WHEN transaction_type IN ('Withdrawal', 'Purchase') THEN -transaction_amount 
               ELSE 0 
           END) AS end_of_month_balance
FROM Customer_Transactions
GROUP BY customer_id, MONTH(transaction_date);


