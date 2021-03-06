/*	Исходный запрос
	Что считаем:
	Какие заказчики заказывали товары определённого поставщика (12 Id)
	Общая сумма и количество единиц, сколько заказов всего по конкретному товару.
		Фильтруем все заказы по тому, что счёт был выставлен в день заказа и заказчиков, у которых сумма всех заказов больше 250 000.
*/
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

Select		ord.CustomerID
		,	det.StockItemID
		,	SUM(det.UnitPrice)	As UnitPrice
		,	SUM(det.Quantity)	AS Quantity
		,	COUNT(ord.OrderID)	AS OrderID
FROM Sales.Orders AS ord 
	JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID 
		JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID 
			JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID 
				JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID 
WHERE Inv.BillToCustomerID != ord.CustomerID 
	AND (Select SupplierId FROM Warehouse.StockItems AS It Where It.StockItemID = det.StockItemID) = 12 
	AND (	SELECT SUM(Total.UnitPrice*Total.Quantity) 
			FROM Sales.OrderLines AS Total Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID WHERE ordTotal.CustomerID = Inv.CustomerID
		) > 250000 AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0 
GROUP BY ord.CustomerID, det.StockItemID 
ORDER BY ord.CustomerID, det.StockItemID

/* ------------------------------------------------------------------------------------------------------------------------------------------
Время синтаксического анализа и компиляции SQL Server: 
 время ЦП = 62 мс, истекшее время = 144 мс.

(затронуто строк: 3619)

------------------------------------------------------------------------------------------------	*/


/*		STEP1
		Начнем по тихоньку убирать лишнее :)
		Уберем лишние связи (по моему мнению они не используются) (Sales.CustomerTransactions,Warehouse.StockItemTransactions) 
		В условии WHERE уберем вычитание дней, дешевле будет поставить равно или не равно  Inv.InvoiceDate = ord.OrderDate
		Перенесем 1 джоин заказчиков заказывали товары определённого поставщика (12 Id) из Условия WHERE
*/

Select		ord.CustomerID
		,	det.StockItemID
		,	SUM(det.UnitPrice)	As UnitPrice
		,	SUM(det.Quantity)	AS Quantity
		,	COUNT(ord.OrderID)	AS OrderID
FROM Sales.Orders AS ord 
	JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID 
		JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID 
			JOIN  Warehouse.StockItems si ON det.StockItemID = si.StockItemID AND si.SupplierID=12
--			JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID 
--				JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID 
WHERE Inv.BillToCustomerID != ord.CustomerID 
/*	AND (Select SupplierId FROM Warehouse.StockItems AS It Where It.StockItemID = det.StockItemID) = 12 */
	AND (	SELECT SUM(Total.UnitPrice*Total.Quantity) 
			FROM Sales.OrderLines AS Total Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID WHERE ordTotal.CustomerID = Inv.CustomerID
		) > 250000 AND Inv.InvoiceDate = ord.OrderDate
GROUP BY ord.CustomerID, det.StockItemID 
ORDER BY ord.CustomerID, det.StockItemID

/* --------------------------------------------------------------------------------
	Уменьшили вдвое 

Время синтаксического анализа и компиляции SQL Server: 
 время ЦП = 31 мс, истекшее время = 51 мс.

(затронуто строк: 3619)
-----------------------------------------------------------------------------------*/

/*	STEP2
	Судя по плану (много вложенных циклов на табличке Invoce) попробуем перестроить запрос через неё + вынесем запрос из условия в CTE
*/


WITH CTE_Customers AS (
	SELECT o.CustomerID FROM Sales.OrderLines ol
	INNER JOIN Sales.Orders o ON ol.OrderID = o.OrderID
	GROUP BY o.CustomerID
	HAVING SUM(ol.UnitPrice * ol.Quantity) > 250000
)
SELECT ord.CustomerID, 
       det.StockItemID, 
       SUM(det.UnitPrice) AS [TotalUnitPrice], 
       SUM(det.Quantity) AS [TotalQuantity], 
       COUNT(ord.OrderID) AS [TotalOrdersCount]
FROM Sales.Invoices Inv
	 INNER JOIN Sales.Orders ord ON Inv.OrderID = ord.OrderID
     INNER JOIN Sales.OrderLines det ON ord.OrderID = det.OrderID
	 INNER JOIN Warehouse.StockItems si ON det.StockItemID = si.StockItemID
	 INNER JOIN CTE_Customers bc ON ord.CustomerID = bc.CustomerID
WHERE Inv.BillToCustomerID != ord.CustomerID
    AND si.SupplierID = 12
	AND Inv.InvoiceDate = ord.OrderDate	
GROUP BY ord.CustomerID, 
         det.StockItemID
ORDER BY ord.CustomerID, 
         det.StockItemID;
--
--		Судя по количеству времени ЦП фокус с оптимизацией удался, скорее всего есть еще варианты к сожалению ничего более хитрого не придумал. 
--		
/*----------------------------------------------------------------------------
Тест:
	Было в 1 селекте
				Время синтаксического анализа и компиляции SQL Server: 
				 время ЦП = 0 мс, истекшее время = 0 мс.
				
				 Время работы SQL Server:
				   Время ЦП = 0 мс, затраченное время = 0 мс.
				Время синтаксического анализа и компиляции SQL Server: 
				 время ЦП = 78 мс, истекшее время = 82 мс.
				
				(затронуто строк: 3619)
				Таблица "StockItemTransactions". Число просмотров 1, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 66, lob физических чтений 0, lob упреждающих чтений 0.
				Таблица "StockItemTransactions". Считано сегментов 1, пропущено 0.
				Таблица "OrderLines". Число просмотров 4, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 700, lob физических чтений 0, lob упреждающих чтений 0.
				Таблица "OrderLines". Считано сегментов 2, пропущено 0.
				Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
				Таблица "CustomerTransactions". Число просмотров 5, логических чтений 261, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
				Таблица "Orders". Число просмотров 2, логических чтений 316, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
				Таблица "Invoices". Число просмотров 1, логических чтений 44525, физических чтений 0, упреждающих чтений 14, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
				Таблица "StockItems". Число просмотров 1, логических чтений 2, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
				
				(затронута одна строка)
				
				 Время работы SQL Server:
				   Время ЦП = 422 мс, затраченное время = 614 мс.
				Время синтаксического анализа и компиляции SQL Server: 
				 время ЦП = 0 мс, истекшее время = 0 мс.
				
				 Время работы SQL Server:
				   Время ЦП = 0 мс, затраченное время = 0 мс.
	Стало:
			Время синтаксического анализа и компиляции SQL Server: 
			 время ЦП = 0 мс, истекшее время = 0 мс.
			
			 Время работы SQL Server:
			   Время ЦП = 0 мс, затраченное время = 0 мс.
			Время синтаксического анализа и компиляции SQL Server: 
			 время ЦП = 0 мс, истекшее время = 0 мс.
			
			(затронуто строк: 3619)
			Таблица "OrderLines". Число просмотров 4, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 700, lob физических чтений 0, lob упреждающих чтений 0.
			Таблица "OrderLines". Считано сегментов 2, пропущено 0.
			Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 52, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
			Таблица "Invoices". Число просмотров 11767, логических чтений 61156, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
			Таблица "Orders". Число просмотров 2, логических чтений 316, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
			Таблица "StockItems". Число просмотров 1, логических чтений 2, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
			
			(затронута одна строка)
			
			 Время работы SQL Server:
			   Время ЦП = 110 мс, затраченное время = 243 мс.
			Время синтаксического анализа и компиляции SQL Server: 
			 время ЦП = 0 мс, истекшее время = 0 мс.
			
			 Время работы SQL Server:
			   Время ЦП = 0 мс, затраченное время = 0 мс.