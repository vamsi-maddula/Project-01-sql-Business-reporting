create database retail;
use retail;
select name from sys.tables;
'EXEC sp_rename 'Sheet1$' , sheet; 
select count(*) from sheet;
delete sheet;
drop table sheet;'
EXEC sp_rename 'Sheet1$' , sheet;
select count(*) from sheet; 
select TOP 10 * from sheet;

# REVENUE & TIME ANALYSIS

select Sum(Revenue) as 
TotalRevenue from sheet;

SELECT YEAR(OrderDate), MONTH(OrderDate), SUM(Revenue)
FROM sheet
GROUP BY YEAR(OrderDate), MONTH(OrderDate);


WITH m AS (
 SELECT YEAR(OrderDate) Year, MONTH(OrderDate) Month, SUM(Revenue) TotalRevenue
 FROM sheet
 GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT Year, Month,TotalRevenue,
       (TotalRevenue- LAG(TotalRevenue) over (order by Year,Month)) /
       Nullif(LAG(TotalREvenue) OVer(order by Year,Month),0) * 100 AS Growthper
FROM m;

SELECT OrderDate,
       SUM(Revenue) AS DailyRevenue,
       SUM(SUM(Revenue)) OVER (ORDER BY OrderDate) AS RunningTotal
FROM sheet
GROUP BY OrderDate;

WITH m AS (
 SELECT YEAR(OrderDate) Year, MONTH(OrderDate) Month, SUM(Revenue) TotalRevenue
 FROM sheet
 GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT Year, Month,TotalRevenue,
       AVG(TotalRevenue) over (order by Month,Year ) as rollingmonthavg
	   from m;

WITH m AS (
 SELECT YEAR(OrderDate) Year, MONTH(OrderDate) Month, SUM(Revenue) TotalRevenue
 FROM sheet
 GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT Year, Month,TotalRevenue,
       AVG(TotalRevenue) over (order by Month,Year rows 2 preceding) as rolling3monthavg
	   from m;


 SELECT
 YEAR(OrderDate)as Year, MONTH(OrderDate) as Month, sum(Revenue) as Revenue
FROM sheet
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Revenue DESC;

 SELECT  Top 5
 YEAR(OrderDate)as Year, MONTH(OrderDate) as Month, sum(Revenue) as Revenue
FROM sheet
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Revenue DESC;


SELECT AVG(MonthlyRevenue) as RevenuebyMonth
FROM (
 SELECT SUM(Revenue) AS MonthlyRevenue
 FROM sheet
 GROUP BY YEAR(OrderDate), MONTH(OrderDate)
) Monthlydata;

SELECT YEAR(OrderDate)  year
, SUM(Revenue) TotalRevenue
FROM sheet
GROUP BY YEAR(OrderDate);


SELECT Revenue- LAG(Revenue)
OVER(ORDER BY Year,Month)
AS RevenueChange
FROM (
 SELECT YEAR(OrderDate) Year,
  MONTH(OrderDate) Month,
  SUM(Revenue) Revenue
 FROM sheet
 GROUP BY YEAR(OrderDate), MONTH(OrderDate)
) Monthlydata;


SELECT YEAR(OrderDate) year,
 MONTH(OrderDate) month,
       SUM(Revenue) / (SELECT SUM(Revenue) FROM sheet) *  100 as Revenueshare_byMonth
FROM sheet
GROUP by Month(OrderDate),Year(Orderdate);


# Customer analytics 

SELECT CustomerID, SUM(Revenue) as TotalRevenue
FROM sheet
GROUP BY CustomerID;



select count(distinct CustomerID) from sheet;

SELECT TOP 10 CustomerID, SUM(Revenue) Revenue
FROM sheet group by CustomerID;


SELECT CustomerID, OrderDate,
ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY OrderDate) Sequence
FROM sheet;

SELECT CustomerID, MIN(OrderDate) as Firstpurchase         'firstpurchase'
FROM sheet
GROUP BY CustomerID;

SELECT CustomerID, MAX(OrderDate) as lastpurchase   'lastpurcahse'
FROM sheet
GROUP BY CustomerID;

SELECT CustomerID          'repeated customers'
FROM sheet
GROUP BY CustomerID
HAVING count(*) >1;

SELECT AVG(CustomerRevenue) as CustomerRevenue    'customer revenue'
FROM (
 SELECT CustomerID, SUM(Revenue) CustomerRevenue
 FROM sheet
 GROUP BY CustomerID
)data;

SELECT CustomerID, SUM(Revenue) AS CLV  'life time value'
FROM sheet
GROUP BY CustomerID;

SELECT Region, COUNT(DISTINCT CustomerID)
FROM sheet group by Region, CustomerID;            'Region count'  



SELECT CustomerID
FROM sheet
GROUP BY CustomerID
HAVING MAX(OrderDate) < DATEADD(day,-90,GETDATE());   'NO purchase from last 90days'


# Product and margin analysis 

'product revenue'
SELECT ProductName, SUM(Revenue)TotalRevenue
FROM sheet
GROUP BY ProductName;

SELECT ProductName, SUM(Margin) margin       'product margin'
FROM sheet
GROUP BY ProductName;

SELECT ProductName, SUM(Margin),
RANK() OVER(ORDER BY SUM(Margin) DESC) AS Rank           'product rank'
FROM sheet
GROUP BY ProductName;

SELECT Category, SUM(Revenue),
RANK() OVER(ORDER BY SUM(Revenue) DESC)             'category rank'
FROM sheet
GROUP BY Category;


SELECT *
FROM (
 SELECT Region, ProductName, SUM(Revenue) Revenue,
 ROW_NUMBER() OVER(PARTITION BY Region ORDER BY SUM(Revenue) DESC) rn
 FROM sheetSELECT ProductName
FROM RetailSales
GROUP BY ProductName
HAVING SUM(Margin)/SUM(Revenue)<0.2;
 GROUP BY Region,ProductName                      'TOP 5 products by region'
) data
WHERE rn<=5;


SELECT ProductName
FROM sheet
GROUP BY ProductName
HAVING SUM(Margin)/SUM(Revenue)<0.4;     'margin < 40 per'


SELECT ProductName,
SUM(Revenue)/(SELECT SUM(Revenue) FROM sheet) * 100 as percentcontribution
FROM sheet
GROUP BY ProductName;            'revenue %'

SELECT ProductName
FROM sheet
GROUP BY ProductName
HAVING SUM(Quantity)>100 AND SUM(Margin)<1000;      'with high profitlow margin'

SELECT Category, SUM(Margin) margin   
FROM sheet
GROUP BY Category;                            'category profitability'


SELECT ProductName, AVG(Quantity)avgQuanity,UnitPrice
FROM sheet
GROUP BY ProductName,UnitPrice;                  'price sensitivity'



# Data quality and Reconcilation 


SELECT * FROM sheet
WHERE OrderDate IS NULL OR Revenue IS NULL;

SELECT * FROM sheet
WHERE Revenue <> Quantity * UnitPrice;  'revenue validation'

SELECT * FROM sheet
WHERE Revenue<0;

SELECT OrderID,COUNT(*) 
FROM sheet
GROUP BY OrderID HAVING COUNT(*)>1;

SELECT * FROM sheet
WHERE Margin <> Revenue-Cost;

select * from sheet;

SELECT COUNT(*),COUNT(DISTINCT OrderID) FROM sheet;

SELECT * FROM sheet
WHERE Region IS NULL;

SELECT DISTINCT Category FROM sheet;


SELECT *
FROM sheet
WHERE Revenue > (
        SELECT AVG(Revenue) + 2 * STDEV(Revenue)
        FROM sheet
)
OR Revenue < (
        SELECT AVG(Revenue) - 2 * STDEV(Revenue)
        FROM sheet
);
' for outliers'

SELECT *
FROM sheet
WHERE Revenue > (
    SELECT AVG(Revenue)
    FROM sheet
) * 2;


SELECT avg
(Margin/Revenue)*100 FROM sheet;


