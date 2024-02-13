-- Top 3 rows of data for inspection
SELECT TOP 3 *
FROM dbo.Orders$

-- Check countries represented in data
SELECT DISTINCT(Country)
FROM dbo.Orders$

-- Since only U.S. is represented let's now check top 5 states by sales with the corresponding dollar amount
SELECT TOP 5 count(Sales) as "SalesCount", SUM(Sales) as "Sales$Amt", State
FROM dbo.Orders$
GROUP BY State
ORDER BY count(Sales) DESC

-- Let's now check the inverse to see if the states with the top 5 distinct sales are also the top 5 in terms of dollar amount
SELECT TOP 5 State, SUM(Sales) as "Sales$Amt"
FROM dbo.Orders$
GROUP BY State
ORDER BY SUM(Sales) DESC
-- All is the same except 4 and 5 spots are flipped

-- Let's now look at Orders by Year
-- First we will get some aggregated measures by year
SELECT YEAR("Order Date") as 'Year', SUM(Sales) as 'Tot$Sales', SUM(Profit) as 'Tot$Profit', COUNT("Order ID") as 'Tot#Orders'
FROM dbo.Orders$
GROUP BY YEAR("Order Date")
ORDER BY YEAR("Order Date") ASC

-- Let's now check if our profits are increasing YoY
SELECT YEAR("Order Date") as "Year", SUM(Profit) as "Tot$Profit",
	CASE
		WHEN LAG(SUM(Profit)) OVER (ORDER BY YEAR("Order Date")) < SUM(Profit) THEN 'INCREASED'
		WHEN LAG(SUM(Profit)) OVER (ORDER BY YEAR("Order Date")) > SUM(Profit) THEN 'DECREASED'
		WHEN LAG(SUM(Profit)) OVER (ORDER BY YEAR("Order Date")) = SUM(Profit) THEN 'EQUAL'
	END
FROM dbo.Orders$
GROUP BY YEAR("Order Date")
ORDER BY YEAR("Order Date")
-- There is an increase in Profit every year

-- Let's now do the same with total orders over the years
SELECT YEAR("Order Date") as "Year", COUNT("Order ID"),
	CASE
		WHEN LAG(COUNT("Order ID")) OVER (ORDER BY YEAR("Order Date")) < COUNT("Order ID") THEN 'INCREASED'
		WHEN LAG(COUNT("Order ID")) OVER (ORDER BY YEAR("Order Date")) > COUNT("Order ID") THEN 'DECREASED'
		WHEN LAG(COUNT("Order ID")) OVER (ORDER BY YEAR("Order Date")) = COUNT("Order ID") THEN 'EQUAL'
	END
FROM dbo.Orders$
GROUP BY YEAR("Order Date")
ORDER BY YEAR("Order Date")
-- There has been an increase in # of orders each year

--Let's now see how Profit is trending monthly
SELECT YEAR("Order Date"), MONTH("Order Date") as "MM", SUM(Profit) as "Prof",
	CASE
		WHEN LAG(SUM(Profit)) OVER (ORDER BY YEAR("Order Date")) < SUM(Profit) THEN 'INCREASED'
		WHEN LAG(SUM(Profit)) OVER (ORDER BY YEAR("Order Date")) > SUM(Profit) THEN 'DECREASED'
		WHEN LAG(SUM(Profit)) OVER (ORDER BY YEAR("Order Date")) = SUM(Profit) THEN 'EQUAL'
	END as "ProfitComparison"
FROM dbo.Orders$
GROUP BY YEAR("Order Date"), MONTH("Order Date")
ORDER BY 1,2

-- Let's now use above to find what months had a decrease in Sales
SELECT *
FROM (SELECT YEAR("Order Date") as "Order Year", MONTH("Order Date") as "Order Month", SUM(Profit) as "Profit",
	CASE
		WHEN LAG(SUM(Profit)) OVER (ORDER BY YEAR("Order Date")) < SUM(Profit) THEN 'INCREASED'
		WHEN LAG(SUM(Profit)) OVER (ORDER BY YEAR("Order Date")) > SUM(Profit) THEN 'DECREASED'
		WHEN LAG(SUM(Profit)) OVER (ORDER BY YEAR("Order Date")) = SUM(Profit) THEN 'EQUAL'
	END as "ProfitComparison"
FROM dbo.Orders$
GROUP BY YEAR("Order Date"), MONTH("Order Date")
) as a
WHERE "ProfitComparison" = 'DECREASED'
ORDER BY "Order Year", "Order Month"
-- It appears that there was a consistent downturn in Profits through the first half of the year. After that there was typically an increase in profit from months 8 through the end of the year

-- Let's now make a query that allows us to see a rollup of MM,DD,YYYY at once
SELECT COUNT([Order ID]) as "TotOrderCount", YEAR([Order Date]) as "Year", MONTH([Order Date]) as "Month", DAY([Order Date]) as "Day"
FROM dbo.Orders$
GROUP BY 
	ROLLUP(
		YEAR([Order Date]), 
		MONTH([Order Date]), 
		DAY([Order Date]))
ORDER BY YEAR([Order Date]), MONTH([Order Date]), DAY([Order Date])

-- Let's now take a look at the products
SELECT COUNT("Order ID") as "CntOrders", Category, "Sub-Category"
FROM dbo.Orders$
GROUP BY Category, [Sub-Category]
ORDER BY CntOrders DESC

-- Let's now check which customers have the most returns
-- Checking Returns table to see what column to use for join
SELECT TOP 3 *
FROM dbo.Returns$

-- Create a join to check returns
SELECT o.[Customer Name], COUNT(o.[Customer Name]) as "CustReturnCount"
FROM dbo.Orders$ as o
INNER JOIN dbo.Returns$ as r
ON o.[Order ID] = r.[Order ID]
GROUP BY  o.[Customer Name], o.[Product Name]
ORDER BY "CustReturnCount" DESC

-- Check which products are being returned the most
SELECT o.[Product Name], COUNT(o.[Product Name]) as "ProdReturnCount"
FROM dbo.Orders$ as o
INNER JOIN dbo.Returns$ as r
ON o.[Order ID] = r.[Order ID]
GROUP BY o.[Product Name]
ORDER BY "ProdReturnCount" DESC

-- Rank Customers by most orders
SELECT [Customer Name], COUNT([Customer Name]) as [Customer Orders], RANK() OVER(Order by COUNT([Customer Name]) DESC) as "Customer Rank"
FROM dbo.Orders$
GROUP BY [Customer Name]
ORDER BY [Customer Rank] ASC

-- Let's now do something similar for cities & states
SELECT [State], City, SUM(Profit) as "TotProf", RANK() OVER(PARTITION BY State ORDER BY SUM(Profit) DESC) as "CityRank"
FROM dbo.Orders$
GROUP BY City, [State]
