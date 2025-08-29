

THE ANSWERS OF QUESTIONS

 1)Find the top 3 customers who have the maximum count of orders.

 SELECT TOP 3 Cust_ID, Count (Ord_ID)
 FROM e_commerce_data
 GROUP BY Cust_ID
 ORDER BY 2 desc

 2) Find the customer whose order took the maximum time to get shipping.

 select*
 from e_commerce_data

 SELECT Top 1 Cust_ID, DATEDIFF(day, Order_Date, Ship_Date) AS Shipping_Delay
FROM e_commerce_data
ORDER BY Shipping_Delay DESC;

 3) Count the total number of unique customers in January and how many of them
came back every month over the entire year in 2011

SELECT COUNT(DISTINCT Cust_ID) AS Jan_Customers
FROM e_commerce_data
WHERE Order_Date >= '2011-01-01' AND Order_Date < '2011-02-01';

WITH jan_customers AS (
    SELECT DISTINCT Cust_ID
    FROM e_commerce_data
    WHERE Order_Date >= '2011-01-01' AND Order_Date < '2011-02-01'
),
monthly_visits AS (
    SELECT
        Cust_ID,
        MONTH(Order_Date) AS order_month
    FROM e_commerce_data
    WHERE YEAR(Order_Date) = 2011
      AND Cust_ID IN (SELECT Cust_ID FROM jan_customers)
    GROUP BY Cust_ID, MONTH(Order_Date)
),
customers_with_all_months AS (
    SELECT Cust_ID
    FROM monthly_visits
    GROUP BY Cust_ID
    HAVING COUNT(DISTINCT order_month) = 12
)
SELECT COUNT(*) AS Returned_Every_Month
FROM customers_with_all_months;
    
 4) Write a query to return for each user the time elapsed between the first
purchasing and the third purchasing, in ascending order by Customer ID.

 WITH Urun_Satislari AS (
    SELECT 
        Cust_ID,
        CAST(SUBSTRING(Prod_ID, 6, LEN(Prod_ID) - 5) AS INT) AS Prod_ID,  -- 'Prod_' kısmını çıkarıp sayıyı alıyoruz
        COUNT(*) AS Urun_Sayisi
    FROM e_commerce_data
    WHERE CAST(SUBSTRING(Prod_ID, 6, LEN(Prod_ID) - 5) AS INT) IN (11, 14)  -- Ürün 11 ve 14'ü filtreliyoruz
    GROUP BY Cust_ID, CAST(SUBSTRING(Prod_ID, 6, LEN(Prod_ID) - 5) AS INT)  -- Prod_ID'yi sayıya dönüştürüp grupluyoruz
),
Musteri_Toplamlari AS (
    SELECT 
        Cust_ID,
        COUNT(*) AS Toplam_Urun_Satildi
    FROM e_commerce_data
    GROUP BY Cust_ID
)
SELECT 
    us.Cust_ID,
    SUM(CASE WHEN us.Prod_ID = 11 THEN us.Urun_Sayisi ELSE 0 END) AS Urun_11_Sayisi,
    SUM(CASE WHEN us.Prod_ID = 14 THEN us.Urun_Sayisi ELSE 0 END) AS Urun_14_Sayisi,
    mt.Toplam_Urun_Satildi,
    CAST(SUM(CASE WHEN us.Prod_ID = 11 THEN us.Urun_Sayisi ELSE 0 END) AS FLOAT) /
    mt.Toplam_Urun_Satildi AS Urun_11_Orani,
    CAST(SUM(CASE WHEN us.Prod_ID = 14 THEN us.Urun_Sayisi ELSE 0 END) AS FLOAT) /
    mt.Toplam_Urun_Satildi AS Urun_14_Orani
FROM Urun_Satislari us
JOIN Musteri_Toplamlari mt ON us.Cust_ID = mt.Cust_ID
GROUP BY us.Cust_ID, mt.Toplam_Urun_Satildi
HAVING SUM(CASE WHEN us.Prod_ID = 11 THEN 1 ELSE 0 END) > 0
   AND SUM(CASE WHEN us.Prod_ID = 14 THEN 1 ELSE 0 END) > 0
ORDER BY us.Cust_ID;

 CUSTOMER SEGMENTATION

 1)Create a “view” that keeps visit logs of customers on a monthly basis. (For
each log, three field is kept: Cust_id, Year, Month)

2. Create a “view” that keeps the number of monthly visits by users. (Show
separately all months from the beginning business)

IF OBJECT_ID('MonthlyVisitCounts', 'V') IS NOT NULL
    DROP VIEW MonthlyVisitCounts;
GO

CREATE VIEW MonthlyVisitCounts AS
SELECT 
    YEAR(Order_Date) AS Visit_Year,
    MONTH(Order_Date) AS Visit_Month,
    Cust_ID,
    COUNT(*) AS Visit_Count
FROM e_commerce_data
GROUP BY 
    YEAR(Order_Date),
    MONTH(Order_Date),
    Cust_ID;

 3) For each visit of customers, create the next month of the visit as a separate
column.
 
 SELECT
    Cust_ID,
    YEAR(Order_Date) AS Visit_Year,
    MONTH(Order_Date) AS Visit_Month,
    DATEADD(MONTH, 1, Order_Date) AS Next_Month_Date,
    YEAR(DATEADD(MONTH, 1, Order_Date)) AS Next_Visit_Year,
    MONTH(DATEADD(MONTH, 1, Order_Date)) AS Next_Visit_Month
FROM e_commerce_data;

 4) Calculate the monthly time gap between two consecutive visits by each
customer.

SELECT
    Cust_ID,
    Order_Date AS Current_Visit_Date,
    LAG(Order_Date) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS Previous_Visit_Date,
    DATEDIFF(MONTH, 
             LAG(Order_Date) OVER (PARTITION BY Cust_ID ORDER BY Order_Date), 
             Order_Date) AS Month_Gap
FROM e_commerce_data;

5) Categorise customers using average time gaps. Choose the most fitted
labeling model for you.
For example:
o Labeled as churn if the customer hasn't made another purchase in the
months since they made their first purchase.
o Labeled as regular if the customer has made a purchase every month.
Etc.

 WITH VisitDiffs AS (
    SELECT
        Cust_ID,
        Order_Date,
        LAG(Order_Date) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS Prev_Date,
        DATEDIFF(MONTH, 
                 LAG(Order_Date) OVER (PARTITION BY Cust_ID ORDER BY Order_Date), 
                 Order_Date) AS Month_Gap
    FROM e_commerce_data
),
AvgGaps AS (
    SELECT
        Cust_ID,
        COUNT(*) AS Visit_Count,
        AVG(Month_Gap * 1.0) AS Avg_Month_Gap,
        MAX(Order_Date) AS Last_Visit,
        MIN(Order_Date) AS First_Visit,
        DATEDIFF(MONTH, MIN(Order_Date), MAX(Order_Date)) AS Total_Lifetime
    FROM VisitDiffs
    GROUP BY Cust_ID
)
SELECT
    Cust_ID,
    Visit_Count,
    Avg_Month_Gap,
    First_Visit,
    Last_Visit,
    Total_Lifetime,
    CASE 
        WHEN Visit_Count = 1 THEN 'churn'
        WHEN Avg_Month_Gap <= 1 AND Visit_Count >= Total_Lifetime THEN 'regular'
        WHEN Avg_Month_Gap BETWEEN 1 AND 3 THEN 'occasional'
        WHEN Avg_Month_Gap > 3 THEN 'sporadic'
        ELSE 'unclassified'
    END AS Customer_Type
FROM AvgGaps;


 MONTH-WISE RETENTION RATE

 Step 1 : There is already an object named 'MonthlyVisitCounts' in the database.

 Step 2 : Create a view to check if a customer is retained in the next month

 CREATE VIEW MonthlyRetentionCheck AS
SELECT 
    curr.Cust_ID,
    curr.Visit_Year,
    curr.Visit_Month,
    CASE 
        WHEN next.Cust_ID IS NOT NULL THEN 1
        ELSE 0
    END AS Is_Retained
FROM MonthlyVisitCounts curr
LEFT JOIN MonthlyVisitCounts next
    ON curr.Cust_ID = next.Cust_ID
    AND (
        (curr.Visit_Year = next.Visit_Year AND curr.Visit_Month + 1 = next.Visit_Month)
        OR (curr.Visit_Year + 1 = next.Visit_Year AND curr.Visit_Month = 12 AND next.Visit_Month = 1)
    );

Step 3 : Create a view to count total and retained customers per month

CREATE VIEW MonthlyRetentionStats AS
SELECT 
    Visit_Year,
    Visit_Month,
    COUNT(*) AS Total_Customers,
    SUM(Is_Retained) AS Retained_Customers
FROM MonthlyRetentionCheck
GROUP BY Visit_Year, Visit_Month;

Step 4: Final query to calculate the retention rate

 SELECT 
    Visit_Year,
    Visit_Month,
    Total_Customers,
    Retained_Customers,
    1.0 * Retained_Customers / Total_Customers AS Retention_Rate
FROM MonthlyRetentionStats
ORDER BY Visit_Year, Visit_Month;
