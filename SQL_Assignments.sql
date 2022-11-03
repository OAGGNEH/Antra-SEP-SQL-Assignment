/*SQL Assignments */

/*1. List of Persons’ full name, all their fax and phone numbers, as well as the phone number and fax of the company they are working for (if any). */
WITH AllPersons AS (
SELECT
	ap.FullName,
	ap.FaxNumber,
	ap.PhoneNumber,
	sc.PhoneNumber AS company_phone,
	sc.FaxNumber AS company_fax,
	ps.PhoneNumber AS company_phone2,
	ps.FaxNumber AS company_fax2
FROM
	Application.People ap
	LEFT JOIN
	Sales.Customers sc ON ap.PersonID = sc.PrimaryContactPersonID OR ap.PersonID = sc.AlternateContactPersonID
	LEFT JOIN
	Purchasing.Suppliers ps ON ap.PersonID = ps.PrimaryContactPersonID OR ap.PersonID = ps.AlternateContactPersonID
)
SELECT
	FullName,
	FaxNumber,
	PhoneNumber,
	CASE WHEN company_phone IS NULL AND company_phone2 IS NOT NULL THEN company_phone2
		 WHEN company_phone IS NOT NULL AND company_phone2 IS NULL THEN company_phone
		 ELSE company_phone
		 END AS CompanyPhone,
	CASE WHEN company_fax IS NULL AND company_fax2 IS NOT NULL THEN company_fax2
		 WHEN company_fax IS NOT NULL AND company_fax2 IS NULL THEN company_fax
		 ELSE company_fax
		 END AS CompanyFax
FROM
	AllPersons;

/*2. If the customer's primary contact person has the same phone number as the customer’s phone number, list the customer companies. */
SELECT
	sc.CustomerName,
	sc.PhoneNumber AS CustomerPhoneNumber,
	ap.PhoneNumber AS PrimaryContact
FROM
	Sales.Customers sc
	LEFT JOIN
	Application.People ap ON sc.PrimaryContactPersonID = ap.PersonID
WHERE
	sc.PhoneNumber = ap.PhoneNumber;

/*3. List of customers to whom we made a sale prior to 2016 but no sale since 2016-01-01.*/
WITH Priors AS (
SELECT
	*
FROM
	Sales.Orders
WHERE
	OrderDate < '2016-01-01'
)
SELECT
	CustomerID
FROM
	Priors
WHERE
	CustomerID NOT IN (SELECT DISTINCT CustomerID FROM Sales.Orders WHERE OrderDate >= '2016-01-01');

/*4. List of Stock Items and total quantity for each stock item in Purchase Orders in Year 2013*/
SELECT
	si.StockItemName,
	SUM(pol.ReceivedOuters) AS quantity
FROM
	Purchasing.PurchaseOrders po
	JOIN
	Purchasing.PurchaseOrderLines pol ON po.PurchaseOrderID = pol.PurchaseOrderID
	JOIN
	Warehouse.StockItems si ON pol.StockItemID = si.StockItemID
WHERE
	po.OrderDate >= '2013-01-01' AND po.OrderDate < '2014-01-01' AND pol.IsOrderLineFinalized = 1
GROUP BY
	si.StockItemName;

/*5. List of stock items that have at least 10 characters in description.*/
SELECT
	StockItemName
FROM
	Warehouse.StockItems
WHERE
	LEN(StockItemName) >= 10;

/*6. List of stock items that are not sold to the state of Alabama and Georgia in 2014.*/

SELECT 
	DISTINCT (S.StockItemName)
FROM Warehouse.StockItems AS S
EXCEPT(
	SELECT 
		DISTINCT(S.StockItemName)
	FROM 
		Warehouse.StockItems AS S
	JOIN Sales.OrderLines AS OL
	ON S.StockItemID = OL.StockItemID
	JOIN Sales.Orders AS O
	ON OL.OrderID = O.OrderID
	JOIN Sales.Customers AS C
	ON C.CustomerID = O.CustomerID
	JOIN Application.Cities AS CT
	ON C.DeliveryCityID = CT.CityID
	JOIN Application.StateProvinces AS SP
	ON CT.StateProvinceID = SP.StateProvinceID
	WHERE SP.StateProvinceName IN ('Alabama' ,'Georgia')
	AND YEAR(O.OrderDate) = 2014);

/*7. List of States and Avg dates for processing (confirmed delivery date – order date).*/
SELECT
	asp.StateProvinceName,
	AVG(DATEDIFF(day, so.OrderDate, si.ConfirmedDeliveryTime)) AS avg_processing_dates
FROM
	Sales.Orders so
	JOIN
	Sales.Invoices si ON so.OrderID = si.OrderID
	JOIN
	Sales.Customers sc ON so.CustomerID = sc.CustomerID
	JOIN
	Application.Cities ac ON sc.PostalCityID = ac.CityID
	JOIN
	Application.StateProvinces asp ON ac.StateProvinceID = asp.StateProvinceID
GROUP BY
	asp.StateProvinceName;

/*8. List of States and Avg dates for processing (confirmed delivery date – order date) by month.*/
SELECT
	asp.StateProvinceName,
	MONTH(so.OrderDate) AS 'month',
	AVG(DATEDIFF(day, so.OrderDate, si.ConfirmedDeliveryTime)) AS avg_processing_dates
FROM
	Sales.Orders so
	JOIN
	Sales.Invoices si ON so.OrderID = si.OrderID
	JOIN
	Sales.Customers sc ON so.CustomerID = sc.CustomerID
	JOIN
	Application.Cities ac ON sc.PostalCityID = ac.CityID
	JOIN
	Application.StateProvinces asp ON ac.StateProvinceID = asp.StateProvinceID
GROUP BY
	asp.StateProvinceName, MONTH(so.OrderDate)
ORDER BY
	1,
	2;

/*9. List of StockItems that the company purchased more than sold in the year of 2015.*/
WITH Sold AS (
SELECT
	ws.StockItemName,
	SUM(sol.Quantity) AS quantity_sold
FROM
	Sales.Orders so
	JOIN
	Sales.OrderLines sol ON so.OrderID = sol.OrderID
	JOIN
	Warehouse.StockItems ws ON sol.StockItemID = ws.StockItemID
WHERE
	so.OrderDate >= '2015-01-01' AND so.OrderDate < '2016-01-01'
GROUP BY
	ws.StockItemName
),
Purchased AS (
SELECT
	ws.StockItemName,
	SUM(ppol.ReceivedOuters) AS quantity_purchased
FROM
	Purchasing.PurchaseOrders ppo
	JOIN
	Purchasing.PurchaseOrderLines ppol ON ppo.PurchaseOrderID = ppol.PurchaseOrderID
	JOIN
	Warehouse.StockItems ws ON ppol.StockItemID = ws.StockItemID
WHERE
	ppo.OrderDate >= '2015-01-01' AND ppo.OrderDate < '2016-01-01'
GROUP BY
	ws.StockItemName
)
SELECT
	s.StockItemName
FROM
	Sold s
	JOIN
	Purchased p ON s.StockItemName = p.StockItemName
WHERE
	s.quantity_sold < p.quantity_purchased;

/*10. List of Customers and their phone number, together with the primary contact person’s name, to whom we did not sell more than 10 mugs (search by name) in the year 2016.*/
WITH CustomerQuantity AS (
SELECT
	so.CustomerID,
	SUM(sol.Quantity) AS mug_quantity
FROM
	Sales.Orders so
	JOIN
	Sales.OrderLines sol ON so.OrderID = sol.OrderID
WHERE
	sol.Description LIKE '%mug%' AND
	(so.OrderDate >= '2016-01-01' AND so.OrderDate <'2017-01-01')
GROUP BY
	so.CustomerID
HAVING
	SUM(sol.Quantity) <= 10
)
SELECT
	sc.CustomerName,
	sc.PhoneNumber,
	ap.FullName AS PrimaryContactName
FROM
	CustomerQuantity cq
	LEFT JOIN
	Sales.Customers sc ON cq.CustomerID = sc.CustomerID
	LEFT JOIN
	Application.People ap ON sc.PrimaryContactPersonID = ap.PersonID;

/*11. List all the cities that were updated after 2015-01-01.*/
SELECT
	CityName
FROM
	Application.Cities
WHERE
	ValidFrom >= '2015-01-01';

/*12. List all the Order Detail (Stock Item name, delivery address, delivery state, city, country, customer name, customer contact person name, customer phone, quantity) for the date of 2014-07-01. Info should be relevant to that date.*/
SELECT
	ws.StockItemName,
	sc.DeliveryAddressLine1,
	sc.DeliveryAddressLine2,
	asp.StateProvinceName,
	ac.CityName,
	ap1.FullName AS PrimaryContactPerson,
	ap2.FullName AS AlternateContactPerson,
	sc.PhoneNumber,
	sol.Quantity
FROM
	Sales.Orders so
	LEFT JOIN
	Sales.OrderLines sol ON so.OrderID = sol.OrderLineID
	LEFT JOIN
	Warehouse.StockItems ws ON sol.StockItemID = ws.StockItemID
	LEFT JOIN
	Sales.Customers sc ON so.CustomerID = sc.CustomerID
	LEFT JOIN
	Application.People ap1 ON sc.PrimaryContactPersonID = ap1.PersonID
	LEFT JOIN
	Application.People ap2 ON sc.AlternateContactPersonID = ap2.PersonID
	LEFT JOIN
	Application.Cities ac ON sc.DeliveryCityID = ac.CityID
	LEFT JOIN
	Application.StateProvinces asp ON ac.StateProvinceID = asp.StateProvinceID
	LEFT JOIN
	Application.Countries aco ON asp.CountryID = aco.CountryID
WHERE
	OrderDate = '2014-07-01';

/*13. List of stock item groups and total quantity purchased, total quantity sold, and the remaining stock quantity (quantity purchased – quantity sold)*/
WITH QuantityPurchased AS (
SELECT
	wsg.StockGroupName,
	SUM(ppol.ReceivedOuters) AS total_quantity_purchased
FROM
	Warehouse.StockGroups wsg
	LEFT JOIN
	Warehouse.StockItemStockGroups wsisg ON wsg.StockGroupID = wsisg.StockGroupID
	LEFT JOIN
	Purchasing.PurchaseOrderLines ppol ON wsisg.StockItemID = ppol.StockItemID
GROUP BY
	wsg.StockGroupName
),
QuantitySold AS (
SELECT
	wsg.StockGroupName,
	SUM(sol.Quantity) AS total_quantity_sold
FROM
	Warehouse.StockGroups wsg
	LEFT JOIN
	Warehouse.StockItemStockGroups wsisg ON wsg.StockGroupID = wsisg.StockGroupID
	LEFT JOIN
	Sales.OrderLines sol ON wsisg.StockItemID = sol.StockItemID
GROUP BY
	wsg.StockGroupName
)
SELECT
	qp.StockGroupName,
	ISNULL(qp.total_quantity_purchased, 0) AS total_quantity_purchased,
	ISNULL(qs.total_quantity_sold, 0) AS total_quantity_sold,
	ISNULL(qp.total_quantity_purchased - qs.total_quantity_sold, 0) AS remaining_stock_quantity
FROM
	QuantityPurchased qp
	FULL OUTER JOIN
	QuantitySold qs ON qp.StockGroupName = qs.StockGroupName;

/*14. List of Cities in the US and the stock item that the city got the most deliveries in 2016. If the city did not purchase any stock items in 2016, print “No Sales”.*/
WITH Orders AS (
SELECT
	wsi.StockItemName,
	sc.DeliveryCityID,
	sol.Quantity
FROM
	Sales.Orders so
	LEFT JOIN
	Sales.OrderLines sol ON so.OrderID = sol.OrderID
	LEFT JOIN
	Sales.Customers sc ON so.CustomerID = sc.CustomerID
	LEFT JOIN
	Warehouse.StockItems wsi ON sol.StockItemID = wsi.StockItemID
WHERE
	so.ExpectedDeliveryDate >= '2016-01-01' AND so.ExpectedDeliveryDate < '2017-01-01'
),
CityOrders AS (
SELECT
	ac.CityName,
	o.StockItemName,
	SUM(o.Quantity) AS num_deliveries
FROM
	Application.Cities ac
	LEFT JOIN
	Orders o ON ac.CityID = o.DeliveryCityID
GROUP BY
	ac.CityName,
	o.StockItemName
),
CityOrdersRank AS (
SELECT
	*,
	RANK()OVER(PARTITION BY CityName ORDER BY num_deliveries DESC) AS ranks
FROM
	CityOrders
)
SELECT
	CityName,
	ISNULL(StockItemName, 'No Sales') AS most_delivered_stock_item
FROM
	CityOrdersRank
WHERE
	ranks = 1;

/*15. List any orders that had more than one delivery attempt (located in invoice table).*/
SELECT  
	OrderID,
	JSON_VALUE(ReturnedDeliveryData,'$.Events[1].Comment') AS comments
FROM 
	sales.Invoices
WHERE 
	JSON_VALUE(ReturnedDeliveryData,'$.Events[1].Comment') IS NOT NULL;

/*16. List all stock items that are manufactured in China. (Country of Manufacture)*/
SELECT
	StockItemID,
	StockItemName,
	JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS country
FROM
	Warehouse.StockItems
WHERE
	JSON_VALUE(CustomFields, '$.CountryOfManufacture') = 'China';

/*17. Total quantity of stock items sold in 2015, group by country of manufacturing.*/
SELECT
	JSON_VALUE(wsi.CustomFields, '$.CountryOfManufacture') AS country_of_manufacturing,
	SUM(sol.Quantity) AS total_quantity
FROM
	Sales.Orders so
	LEFT JOIN
	Sales.OrderLines sol ON so.OrderID = sol.OrderID
	LEFT JOIN
	Warehouse.StockItems wsi ON sol.StockItemID = wsi.StockItemID
WHERE
	so.OrderDate >= '2015-01-01' AND so.OrderDate < '2016-01-01'
GROUP BY
	JSON_VALUE(wsi.CustomFields, '$.CountryOfManufacture');

/*18. Create a view that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. [Stock Group Name, 2013, 2014, 2015, 2016, 2017]*/
CREATE VIEW Warehouse.QuantityYearStock AS
SELECT
	StockGroupName,
	SUM(CASE WHEN years = 2013 THEN quantity
		 ELSE 0
		 END) AS '2013',
	SUM(CASE WHEN years = 2014 THEN quantity
		 ELSE 0
		 END) AS '2014',
	SUM(CASE WHEN years = 2015 THEN quantity
		 ELSE 0
		 END) AS '2015',
	SUM(CASE WHEN years = 2016 THEN quantity
		 ELSE 0
		 END) AS '2016',
	SUM(CASE WHEN years = 2017 THEN quantity
		 ELSE 0
		 END) AS '2017'
FROM
	(
	SELECT
		wsg.StockGroupName,
		LEFT(so.OrderDate, 4) AS years, 
		SUM(sol.Quantity) as quantity 
	FROM
		Warehouse.StockGroups wsg
		LEFT JOIN
		Warehouse.StockItemStockGroups wsisg ON wsg.StockGroupID = wsisg.StockGroupID
		LEFT JOIN
		Sales.OrderLines sol ON wsisg.StockItemID = sol.StockItemID
		LEFT JOIN
		Sales.Orders so ON sol.OrderID = so.OrderID
	WHERE
		so.OrderDate >= '2013-01-01' AND so.OrderDate < '2018-01-01'
	GROUP BY
		wsg.StockGroupName,
		LEFT(so.OrderDate, 4)
	) a
GROUP BY
	StockGroupName;

SELECT
	*
FROM
	Warehouse.QuantityYearStock;


/*19. Create a view that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. [Year, Stock Group Name1, Stock Group Name2, Stock Group Name3, … , Stock Group Name10]*/
CREATE VIEW Warehouse.QuantityStockYear AS
SELECT
	years,
	SUM(CASE WHEN StockGroupName = 'Novelty Items' THEN quantity
		 ELSE 0
		 END) AS Novelty_Items,
	SUM(CASE WHEN StockGroupName = 'Clothing' THEN quantity
		 ELSE 0
		 END) AS Clothing,
	SUM(CASE WHEN StockGroupName = 'Mugs' THEN quantity
		 ELSE 0
		 END) AS Mugs,
	SUM(CASE WHEN StockGroupName = 'T-Shirts' THEN quantity
		 ELSE 0
		 END) AS T_Shirts,
	SUM(CASE WHEN StockGroupName = 'Airline Novelties' THEN quantity
		 ELSE 0
		 END) AS Airline_Novelties,
	SUM(CASE WHEN StockGroupName = 'Computing Novelties' THEN quantity
		 ELSE 0
		 END) AS Computing_Novelties,
	SUM(CASE WHEN StockGroupName = 'USB Novelties' THEN quantity
		 ELSE 0
		 END) AS USB_Novelties,
	SUM(CASE WHEN StockGroupName = 'Furry Footwear' THEN quantity
		 ELSE 0
		 END) AS Furry_Footwear,
	SUM(CASE WHEN StockGroupName = 'Toys' THEN quantity
		 ELSE 0
		 END) AS Toys,
	SUM(CASE WHEN StockGroupName = 'Packaging Materials' THEN quantity
		 ELSE 0
		 END) AS Packaging_Materials
FROM
	(
	SELECT
		wsg.StockGroupName,
		LEFT(so.OrderDate, 4) AS years, 
		SUM(sol.Quantity) as quantity 
	FROM
		Warehouse.StockGroups wsg
		LEFT JOIN
		Warehouse.StockItemStockGroups wsisg ON wsg.StockGroupID = wsisg.StockGroupID
		LEFT JOIN
		Sales.OrderLines sol ON wsisg.StockItemID = sol.StockItemID
		LEFT JOIN
		Sales.Orders so ON sol.OrderID = so.OrderID
	WHERE
		so.OrderDate >= '2013-01-01' AND so.OrderDate < '2018-01-01'
	GROUP BY
		wsg.StockGroupName,
		LEFT(so.OrderDate, 4)
	) a
GROUP BY
	years;

SELECT
	*
FROM
	Warehouse.QuantityStockYear;

/*20. Create a function, input: order id; return: total of that order. List invoices and use that function to attach the order total to the other fields of invoices. */
DROP FUNCTION IF EXISTS OrderTotal;

CREATE FUNCTION OrderTotal(@OrderID int)
RETURNS int AS BEGIN
RETURN(
		SELECT SUM(IL.Quantity)
		FROM Sales.Invoices AS I
		JOIN Sales.InvoiceLines AS IL
		ON I.InvoiceID = IL.InvoiceID AND I.OrderID = @OrderID)
END;

SELECT 
	InvoiceID, 
	OrderID, 
	dbo.OrderTotal(OrderID) AS OrderTotal
FROM 
	Sales.Invoices;

/*21. Create a new table called ods.Orders. Create a stored procedure, with proper error handling and transactions, that input is a date; when executed, it would find orders of that day, calculate order total, and save the information (order id, order date, order total, customer id) into the new table. If a given date is already existing in the new table, throw an error and roll back. Execute the stored procedure 5 times using different dates. */
DROP TABLE IF EXISTS ods.Orders;

CREATE SCHEMA ods;

CREATE TABLE ods.Orders(
	OrderID INT NOT NULL,
	OrderDate DATE NOT NULL,
	OrderTotal INT NOT NULL,
	CustomerID INT NOT NULL);
	
DROP PROCEDURE IF EXISTS dbo.GetOrderInfo; 

CREATE PROCEDURE dbo.GetOrderInfo
	@OrderDate date
AS
	BEGIN TRY
		BEGIN TRANSACTION 
		IF EXISTS (SELECT * FROM ods.Orders WHERE OrderDate = @OrderDate)
		    RAISERROR ('Error raised in TRY block.This OrderDate already exists', -- Message text.  
               16, -- Severity.  
               1 -- State.  
               )
		ELSE
			BEGIN
			INSERT INTO ods.Orders(OrderID, OrderDate, OrderTotal, CustomerID)
			SELECT OrderID, @OrderDate AS OrderDate, OrderTotal, CustomerID
			FROM
			(SELECT o.OrderID, o.CustomerID, SUM(ol.PickedQuantity) AS OrderTotal
			FROM Sales.Orders o 
			JOIN Sales.OrderLines ol
			ON o.OrderID = ol.OrderID
			WHERE o.OrderDate = @OrderDate
			GROUP BY o.OrderID, o.CustomerID) AS Temp
			COMMIT TRANSACTION 
			END
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
		    DECLARE @ErrorMessage NVARCHAR(4000);  
			DECLARE @ErrorSeverity INT;  
			DECLARE @ErrorState INT;  
			SELECT   
			@ErrorMessage = ERROR_MESSAGE(),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorState = ERROR_STATE();  
			RAISERROR (
			   @ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
               );  
		ROLLBACK TRANSACTION 
	END CATCH;

EXEC dbo.GetOrderInfo @OrderDate = '2015-01-01';
EXEC dbo.GetOrderInfo @OrderDate = '2015-01-02';
EXEC dbo.GetOrderInfo @OrderDate = '2015-01-03';
EXEC dbo.GetOrderInfo @OrderDate = '2015-01-04';
EXEC dbo.GetOrderInfo @OrderDate = '2015-01-05';

/*22. Create a new table called ods.StockItem. It has following columns: [StockItemID], [StockItemName] ,[SupplierID] ,[ColorID] ,[UnitPackageID] ,[OuterPackageID] ,[Brand] ,[Size] ,[LeadTimeDays] ,[QuantityPerOuter] ,[IsChillerStock] ,[Barcode] ,[TaxRate]  ,[UnitPrice],[RecommendedRetailPrice] ,[TypicalWeightPerUnit] ,[MarketingComments]  ,[InternalComments], [CountryOfManufacture], [Range], [Shelflife]. Migrate all the data in the original stock item table. */
SELECT
	[StockItemID], 
	[StockItemName],
	[SupplierID],
	[ColorID],
	[UnitPackageID],
	[OuterPackageID],
	[Brand],
	[Size],
	[LeadTimeDays],
	[QuantityPerOuter],
	[IsChillerStock],
	[Barcode],
	[TaxRate],
	[UnitPrice],
	[RecommendedRetailPrice],
	[TypicalWeightPerUnit],
	[MarketingComments],
	[InternalComments],
	JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
	JSON_VALUE(CustomFields,'$.Range') AS Range, 
	JSON_VALUE(CustomFields,'$.ShelfLife') AS ShelfLife
INTO 
	ods.StockItem
FROM
	Warehouse.StockItems;

SELECT
	*
FROM
	ods.StockItem;

/*23. Rewrite your stored procedure in (21). Now with a given date, it should wipe out all the order data prior to the input date and load the order data that was placed in the next 7 days following the input date.*/
DROP TABLE IF EXISTS ods.Orders;

CREATE TABLE ods.Orders(
	OrderID INT NOT NULL,
	OrderDate DATE NOT NULL,
	OrderTotal INT NOT NULL,
	CustomerID INT NOT NULL);

DROP PROCEDURE IF EXISTS dbo.GetOrderInfo; 

CREATE PROCEDURE dbo.GetOrderInfo
	@OrderDate date
AS
	BEGIN TRY
		BEGIN TRANSACTION 
		IF EXISTS (SELECT * FROM ods.Orders WHERE OrderDate = @OrderDate)
		    RAISERROR ('Error raised in TRY block.This OrderDate already exists',  
               16,
               1
               )
		ELSE
			BEGIN
			INSERT INTO ods.Orders(OrderID, OrderDate, OrderTotal, CustomerID)
			SELECT OrderID, @OrderDate AS OrderDate, OrderTotal, CustomerID
			FROM
			(SELECT o.OrderID, o.CustomerID, SUM(ol.PickedQuantity) AS OrderTotal
			FROM Sales.Orders o 
			JOIN Sales.OrderLines ol
			ON o.OrderID = ol.OrderID
			WHERE o.OrderDate = @OrderDate
			GROUP BY o.OrderID, o.CustomerID) AS Temp
			COMMIT TRANSACTION 
			END
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
		    DECLARE @ErrorMessage NVARCHAR(4000);  
			DECLARE @ErrorSeverity INT;  
			DECLARE @ErrorState INT;  
			SELECT   
			@ErrorMessage = ERROR_MESSAGE(),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorState = ERROR_STATE();  
			RAISERROR (
			   @ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
               );  
		ROLLBACK TRANSACTION 
	END CATCH
GO

DROP PROCEDURE IF EXISTS dbo.RemoveOrderInfo;

CREATE PROCEDURE dbo.RemoveOrderInfo
	@OrderDate date
AS
	BEGIN TRY
		BEGIN TRANSACTION 
		IF NOT EXISTS (SELECT * FROM ods.Orders WHERE OrderDate < @OrderDate)
		    RAISERROR ('Error raised in TRY block.This OrderDate does not exist', 
               16,
               1
               )
		ELSE
			BEGIN
			DELETE FROM ods.Orders WHERE OrderDate < @OrderDate
			COMMIT TRANSACTION 
			END
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
		    DECLARE @ErrorMessage NVARCHAR(4000);  
			DECLARE @ErrorSeverity INT;  
			DECLARE @ErrorState INT;  
			SELECT   
			@ErrorMessage = ERROR_MESSAGE(),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorState = ERROR_STATE();  
			RAISERROR (
			   @ErrorMessage,
               @ErrorSeverity, 
               @ErrorState
               );  
		ROLLBACK TRANSACTION 
	END CATCH;

DROP PROCEDURE IF EXISTS dbo.WipeOutLoad;

CREATE PROCEDURE dbo.WipeOutLoad
	@OrderDate DATE
AS
	DECLARE @OrderDateF DATE
	EXEC dbo.RemoveOrderInfo @OrderDate
	EXEC dbo.GetOrderInfo @OrderDate
	SELECT @OrderDateF = CONVERT(DATE,DATEADD(DAY,1,@OrderDate))
	EXEC dbo.GetOrderInfo @OrderDateF
	SELECT @OrderDateF = CONVERT(DATE,DATEADD(DAY,2,@OrderDate))
	EXEC dbo.GetOrderInfo @OrderDateF
	SELECT @OrderDateF = CONVERT(DATE,DATEADD(DAY,3,@OrderDate))
	EXEC dbo.GetOrderInfo @OrderDateF
	SELECT @OrderDateF = CONVERT(DATE,DATEADD(DAY,4,@OrderDate))
	EXEC dbo.GetOrderInfo @OrderDateF
	SELECT @OrderDateF = CONVERT(DATE,DATEADD(DAY,5,@OrderDate))
	EXEC dbo.GetOrderInfo @OrderDateF
	SELECT @OrderDateF = CONVERT(DATE,DATEADD(DAY,6,@OrderDate))
	EXEC dbo.GetOrderInfo @OrderDateF
GO

EXEC dbo.WipeOutLoad @OrderDate = '2015-01-18';
SELECT  DISTINCT OrderDate FROM ods.Orders;

/*24. Consider the JSON file: Looks like that it is our missed purchase orders. Migrate these data into Stock Item, Purchase Order and Purchase Order Lines tables. Of course, save the script.*/
DECLARE @json NVARCHAR(MAX),@json2 NVARCHAR(MAX),@json3 NVARCHAR(MAX);
DECLARE @test NVARCHAR(MAX);
SELECT @json = '{
   "PurchaseOrders":[
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":[
            6,	
            7
         ],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
      },
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-025",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
      }
   ]
}';
SET @json2 = (
	SELECT
		*
	FROM OPENJSON(@json)
	WITH(
	[PurchaseOrders] nvarchar(max) as json
	) 
);

SET @json3 =(
SELECT 
StockItemName,Supplier,UnitPackageId,ISNULL(OuterPackageId,OuterPackageId2) AS OuterPackageId,Brand,
LeadTimeDays,QuantityPerOuter,TaxRate,UnitPrice,RecommendedRetailPrice,TypicalWeightPerUnit,[CustomFields.CountryOfManufacture],
[CustomFields.Range],OrderDate,DeliveryMethod,ExpectedDeliveryDate,SupplierReference
FROM OPENJSON (@json2)
WITH(
StockItemName NVARCHAR(50) '$.StockItemName',
Supplier INT '$.Supplier',
UnitPackageId INT '$.UnitPackageId',
Brand NVARCHAR(50) '$.Brand',
LeadTimeDays INT '$.LeadTimeDays',
QuantityPerOuter INT '$.QuantityPerOuter',
TaxRate  DECIMAL(18,3) '$.TaxRate',
UnitPrice DECIMAL(18,2) '$.UnitPrice',
RecommendedRetailPrice DECIMAL(18,2) '$.RecommendedRetailPrice',
TypicalWeightPerUnit  DECIMAL(18,3) '$.TypicalWeightPerUnit',
[CustomFields.CountryOfManufacture] NVARCHAR(50)  '$.CountryOfManufacture',
[CustomFields.Range] NVARCHAR(50) '$.Range',
OrderDate NVARCHAR(50) '$.OrderDate',
DeliveryMethod NVARCHAR(50) '$.DeliveryMethod',
ExpectedDeliveryDate NVARCHAR(50) '$.ExpectedDeliveryDate',
SupplierReference NVARCHAR(MAX) '$.SupplierReference',
OuterPackage NVARCHAR(MAX) '$.OuterPackageId'  AS JSON,
OuterPackageId2 NVARCHAR(MAX) '$.OuterPackageId'
)
OUTER APPLY OPENJSON(OuterPackage) WITH (
OuterPackageId INT '$')
FOR JSON PATH);

WITH TEMP2 AS(
SELECT *
FROM OPENJSON(@json3)
WITH(
StockItemName NVARCHAR(50) '$.StockItemName',
SupplierID INT '$.Supplier',
UnitPackageID INT '$.UnitPackageId',
OuterPackageID INT '$.OuterPackageId',
Brand NVARCHAR(50) '$.Brand',
LeadTimeDays INT '$.LeadTimeDays',
QuantityPerOuter INT '$.QuantityPerOuter',
TaxRate  DECIMAL(18,3) '$.TaxRate',
UnitPrice DECIMAL(18,2) '$.UnitPrice',
RecommendedRetailPrice DECIMAL(18,2) '$.RecommendedRetailPrice',
TypicalWeightPerUnit  DECIMAL(18,3) '$.TypicalWeightPerUnit',
[CustomFields] NVARCHAR(MAX)  '$.CustomFields' AS JSON,
OrderDate NVARCHAR(50) '$.OrderDate',
DeliveryMethod NVARCHAR(50) '$.DeliveryMethod',
ExpectedDeliveryDate NVARCHAR(50) '$.ExpectedDeliveryDate',
SupplierReference NVARCHAR(MAX) '$.SupplierReference'))

INSERT INTO WideWorldImporters.Warehouse.StockItems(
StockItemName,
SupplierID,
UnitPackageID,
OuterPackageID,
Brand,
LeadTimeDays,
QuantityPerOuter,
IsChillerStock,
TaxRate,
UnitPrice,
RecommendedRetailPrice,
TypicalWeightPerUnit,
CustomFields,
LastEditedBy)
SELECT 
		CONCAT(StockItemName,' version 1'),
		SupplierID,
		UnitPackageID,
		OuterPackageID,
		Brand,
		LeadTimeDays,
		QuantityPerOuter,
		0,
		TaxRate,
		UnitPrice,
		RecommendedRetailPrice,
		TypicalWeightPerUnit,
		CustomFields,
		1
FROM TEMP2
ORDER BY SupplierID, OuterPackageID
OFFSET 0 ROWS
FETCH NEXT 1 ROWS ONLY; 

INSERT INTO WideWorldImporters.Warehouse.StockItems(
StockItemName,
SupplierID,
UnitPackageID,
OuterPackageID,
Brand,
LeadTimeDays,
QuantityPerOuter,
IsChillerStock,
TaxRate,
UnitPrice,
RecommendedRetailPrice,
TypicalWeightPerUnit,
CustomFields,
LastEditedBy)
SELECT  
		CONCAT(StockItemName,' version 2'),
		SupplierID,
		UnitPackageID,
		OuterPackageID,
		Brand,
		LeadTimeDays,
		QuantityPerOuter,
		0,
		TaxRate,
		UnitPrice,
		RecommendedRetailPrice,
		TypicalWeightPerUnit,
		CustomFields,
		1
FROM TEMP2
ORDER BY SupplierID, OuterPackageID
OFFSET 1 ROWS
FETCH NEXT 1 ROWS ONLY; 

INSERT INTO WideWorldImporters.Warehouse.StockItems(
StockItemName,
SupplierID,
UnitPackageID,
OuterPackageID,
Brand,
LeadTimeDays,
QuantityPerOuter,
IsChillerStock,
TaxRate,
UnitPrice,
RecommendedRetailPrice,
TypicalWeightPerUnit,
CustomFields,
LastEditedBy)
SELECT  
		CONCAT(StockItemName,' version 3'),
		SupplierID,
		UnitPackageID,
		OuterPackageID,
		Brand,
		LeadTimeDays,
		QuantityPerOuter,
		0,
		TaxRate,
		UnitPrice,
		RecommendedRetailPrice,
		TypicalWeightPerUnit,
		CustomFields,
		1
FROM TEMP2
ORDER BY SupplierID, OuterPackageID
OFFSET 2 ROWS
FETCH NEXT 1 ROWS ONLY; 

DELETE FROM WideWorldImporters.Warehouse.StockItems WHERE StockItemName LIKE '%Panzer Video Game version%'
SELECT * FROM WideWorldImporters.Warehouse.StockItems

/*25. Revisit your answer in (19). Convert the result in JSON string and save it to the server using TSQL FOR JSON PATH.*/
SELECT
	*
FROM 
	Warehouse.QuantityStockYear
FOR JSON AUTO;

/*26. Revisit your answer in (19). Convert the result into an XML string and save it to the server using TSQL FOR XML PATH.*/
SELECT
	*
FROM
	Warehouse.QuantityStockYear
FOR XML AUTO,ELEMENTS;

/*27. Create a new table called ods.ConfirmedDeviveryJson with 3 columns (id, date, value) . Create a stored procedure, input is a date. The logic would load invoice information (all columns) as well as invoice line information (all columns) and forge them into a JSON string and then insert into the new table just created. Then write a query to run the stored procedure for each DATE that customer id 1 got something delivered to him.*/
DROP TABLE IF EXISTS ods.ConfirmedDeviveryJson;

CREATE TABLE ods.ConfirmedDeviveryJson(
	id INT IDENTITY,
	date DATE,
	value nvarchar(MAX)
);

CREATE PROCEDURE dbo.GetInvoiceInfo
	@OrderDate date
AS
	DECLARE @json nvarchar(MAX);
	SET @json = (
	SELECT 
       O.InvoiceID
      ,O.CustomerID
      ,O.BillToCustomerID
      ,O.OrderID
      ,O.DeliveryMethodID
      ,O.ContactPersonID
      ,O.AccountsPersonID
      ,O.SalespersonPersonID
      ,O.PackedByPersonID
      ,O.InvoiceDate
      ,O.CustomerPurchaseOrderNumber
      ,O.IsCreditNote
      ,O.CreditNoteReason
      ,O.Comments
      ,O.DeliveryInstructions
      ,O.InternalComments
      ,O.TotalDryItems
      ,O.TotalChillerItems
      ,O.DeliveryRun
      ,O.RunPosition
      ,O.ReturnedDeliveryData
      ,O.ConfirmedDeliveryTime
      ,O.ConfirmedReceivedBy
      ,O.LastEditedBy AS OrderLastEdit
      ,O.LastEditedWhen AS OrderLastEditWhen
	  ,OL.InvoiceLineID
      ,OL.StockItemID
      ,OL.Description
      ,OL.PackageTypeID
      ,OL.Quantity
      ,OL.UnitPrice
      ,OL.TaxRate
      ,OL.TaxAmount
      ,OL.LineProfit
      ,OL.ExtendedPrice
      ,OL.LastEditedBy AS OrderLineLastEdit
      ,OL.LastEditedWhen AS OrderLineLastEditWhen
	FROM Sales.Invoices AS O 
	JOIN Sales.InvoiceLines AS OL
	ON O.InvoiceID = OL.InvoiceID AND O.InvoiceDate = @OrderDate
	FOR JSON PATH)
INSERT INTO ods.ConfirmedDeviveryJson(date,value) VALUES(@OrderDate,@json)
GO

DECLARE @param DATE
DECLARE curs CURSOR LOCAL FAST_FORWARD FOR
    SELECT DISTINCT CONVERT(DATE,ConfirmedDeliveryTime) AS OrderDate
	FROM 
	Sales.Invoices WHERE CustomerID = 1
OPEN curs
FETCH NEXT FROM curs INTO @param
WHILE @@FETCH_STATUS = 0 BEGIN
    EXEC dbo.GetInvoiceInfo  @param
    FETCH NEXT FROM curs INTO @param
END
CLOSE curs
DEALLOCATE curs;

SELECT * FROM ods.ConfirmedDeviveryJson;