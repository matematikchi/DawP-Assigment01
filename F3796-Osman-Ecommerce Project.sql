CREATE DATABASE E_Commerce ;
USE E_Commerce 

ALTER TABLE dbo.Market_Fact ADD CONSTRAINT FK1 FOREIGN KEY (Ord_ID) REFERENCES dbo.Orders_Dimen 

ALTER TABLE dbo.Market_Fact ADD CONSTRAINT FK2 FOREIGN KEY (Prod_ID) REFERENCES dbo.prod_dimen

ALTER TABLE dbo.Market_Fact ADD CONSTRAINT FK3 FOREIGN KEY (Ship_ID) REFERENCES dbo.Shipping_Dimen

ALTER TABLE dbo.Market_Fact ADD CONSTRAINT FK4 FOREIGN KEY (Cust_ID) REFERENCES dbo.cust_dimen



select A.Sales, A.Discount, A.Order_Quantity, A.Product_Base_Margin, B.*,C.*,D.*,E.*
INTO combined_table
  from market_fact A
        FULL OUTER JOIN orders_dimen B ON B.Ord_id = A.Ord_id
        FULL OUTER JOIN prod_dimen C ON C.Prod_id = A.Prod_id
        FULL OUTER JOIN cust_dimen D ON D.Cust_id = A.Cust_id
        FULL OUTER JOIN Shipping_Dimen E ON E.Ship_id = A.Ship_id 




--2)


SELECT TOP 3 Cust_ID, Customer_Name, COUNT(DISTINCT Ord_ID) AS count_of_order
FROM combined_table
GROUP BY Cust_ID, Customer_Name
ORDER BY count_of_order DESC 


--3)

Alter table combined_table add DaysTakenForShipping INT;

UPDATE combined_table
SET DaysTakenForShipping = DATEDIFF(DAY,Order_Date,Ship_date)

SELECT DaysTakenForShipping
FROM combined_table

--4)

SELECT top 1 Cust_ID, Customer_Name, Order_Date, Ship_Date, DaysTakenForShipping
FROM combined_table
ORDER BY DaysTakenForShipping DESC


--5)


SELECT MONTH(Order_Date) as month, count(DISTINCT Cust_ID) as count_of_customer
FROM combined_table
WHERE Cust_ID IN(
                    SELECT Cust_ID
                    FROM combined_table
                    WHERE Datepart(MONTH, Order_Date) = 1 and YEAR(Order_Date) = 2011  
                )
AND YEAR(Order_Date) = 2011
GROUP BY MONTH(Order_Date)

--6)

GO

WITH T1 AS
(
SELECT Cust_ID,Order_Date,
MIN(Order_Date) OVER (PARTITION BY Cust_ID order by Order_Date, Cust_ID) first_order,
DENSE_RANK() OVER (PARTITION BY Cust_ID order by Order_Date, Cust_ID) dn_rnk
FROM combined_table 
)
SELECT distinct Cust_ID, Order_Date, DATEDIFF(DAY,first_order,Order_Date ) AS elapsed_time
FROM  T1 
WHERE dn_rnk  = 3 
ORDER BY Cust_ID

--7)



WITH T1 AS 
(
SELECT  Cust_ID, COUNT(Prod_ID) total_prod,
        SUM(CASE WHEN Prod_ID = 'Prod_11' THEN 1 ELSE 0 END) AS PRO_11,
        SUM(CASE WHEN Prod_ID = 'Prod_14' THEN 1 ELSE 0 END) AS PRO_14
FROM combined_table
WHERE Cust_ID in (SELECT Cust_ID
                  FROM combined_table 
                  WHERE Prod_ID = 'Prod_11'
                  INTERSECT
                  SELECT Cust_ID
                  FROM combined_table 
                  WHERE Prod_ID = 'Prod_14')
GROUP BY Cust_ID
)
SELECT Cust_ID, ROUND((cast(PRO_11 as float) ) / cast(total_prod as float),2) RATIO_11,
ROUND((cast(PRO_14 as float)) / cast(total_prod as float),2) RATIO_14
FROM T1


--Customer Segmentation
--1)

CREATE VIEW logs_of_customer
AS 
SELECT Cust_ID, YEAR(Order_Date) [Year], MONTH(Order_Date) [Month]
FROM combined_table

SELECT*
FROM logs_of_customer
ORDER by Cust_ID,[Year]


--2)


CREATE VIEW montly_visits
AS 
SELECT Cust_ID, MONTH(Order_Date) Month_order, COUNT(Order_Date) cnt_order
FROM combined_table
GROUP BY Cust_ID, MONTH(Order_Date)


SELECT*
FROM montly_visits
ORDER BY Cust_ID

--3)


CREATE VIEW Next_Visit_Month AS

SELECT Cust_ID, Year_order , Month_order,
LEAD(Month_order) OVER (partition by Cust_ID order by Year_order, Month_order) Next_Order,
DENSE_RANK() OVER(partition by Cust_ID ORDER BY Year_order, Month_order) dns_rnk
FROM montly_visits
;

--4)

CREATE VIEW montly_time_gaps AS
WITH T2  AS
(
SELECT distinct Cust_ID, Order_Date,
lead(Order_Date) over (partition by Cust_ID ORDER by Order_Date) next_order
FROM combined_table
)
SELECT*, DATEDIFF(MONTH, Order_Date, next_order) as monthly_time_gap
FROM T2


--5 ????