/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

--	Продавали 4 числа	--3,6,7,14,15,16,20
--	Всего продавцов		--2,3,6,7,8,13,14,15,16,20
--	Должно получиться	--2,8,13

/* Через подапрос
*/
--	JOIN 
SELECT ap.PersonID, 
       ap.FullName
FROM [Application].People ap
	LEFT JOIN (	SELECT	DISTINCT SalespersonPersonID
				FROM	Sales.Invoices
				WHERE	InvoiceDate = '20150704'
				) SI ON SI.SalespersonPersonID = ap.PersonID
WHERE	ap.IsSalesperson = 1
		AND SI.SalespersonPersonID is null
;
--	NOT IN
SELECT p.PersonID, 
       p.FullName
FROM [Application].People p
WHERE	p.IsSalesperson = 1
	AND PersonID NOT IN	(	SELECT	DISTINCT SalespersonPersonID
							FROM	Sales.Invoices
							WHERE	InvoiceDate = '20150704'
						 ) 
--	NOT EXISTS
SELECT p.PersonID, 
       p.FullName
FROM Application.People P
WHERE NOT EXISTS (	SELECT SalespersonPersonID
					FROM Sales.Invoices
					WHERE SalespersonPersonID = P.PersonID
					AND InvoiceDate = '20150704'
				)
	AND p.IsSalesperson = 1
ORDER BY PersonID;

--	Через CTE

WITH SalesPersons AS 
(	SELECT DISTINCT SalespersonPersonID 
	FROM Sales.Invoices
	WHERE	InvoiceDate = '20150704'
)	
SELECT ap.PersonID, 
       ap.FullName
FROM Application.People ap
	LEFT JOIN SalesPersons sp ON ap.PersonID = sp.SalespersonPersonID
WHERE ap.IsSalesperson = 1 
	AND sp.SalespersonPersonID IS NULL
;

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
--	Не совсем понятно, минимальная цена это сколько? на сколько помню это минимальная надбавка на товар, что бы покрывала расходы. 
--	Или имеется ввиду товар с самой низкой ценой, тогда почему во множественном числе =)
--	Допустим товары которые находятся в пределе 1/1000 границы от максимальной цены


-- Через подзапросы
SELECT	si.StockItemID
	,	si.StockItemName
	,	si.UnitPrice
--	,	(SELECT MIN(UnitPrice)FROM Warehouse.StockItems)					AS MIN_PRICE
--	,	(SELECT (SELECT MAX(UnitPrice)FROM Warehouse.StockItems) / 1000)	AS MAX_PRICE
FROM Warehouse.StockItems si
WHERE si.UnitPrice BETWEEN	(SELECT MIN(UnitPrice)FROM Warehouse.StockItems) 
					AND		(SELECT (SELECT MAX(UnitPrice)FROM Warehouse.StockItems) / 1000)
order by si.UnitPrice

-- Через CTE
WITH MinMaxPrice
AS
(SELECT 	(SELECT MIN(UnitPrice)FROM Warehouse.StockItems) AS MIN_PRICE
	,		(SELECT (SELECT MAX(UnitPrice)FROM Warehouse.StockItems) / 1000) AS MAX_PRICE
)
SELECT	si.StockItemID
	,	si.StockItemName
	,	si.UnitPrice
--	,	MinMaxPrice.*
FROM Warehouse.StockItems si
	CROSS JOIN MinMaxPrice
WHERE UnitPrice BETWEEN MIN_PRICE AND MAX_PRICE
ORDER BY UnitPrice

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/
-- Предположу что нужны не пять клиентов с максимальными суммами, а 5 максимальных платежей вне зависимости повторяется или клиент

--	Через JOIN 
SELECT		c.CustomerID
		,	c.CustomerName
		,	q1.TransactionAmount
FROM Sales.Customers c
JOIN 
	(
	    SELECT DISTINCT TOP 5 ct2.CustomerID
							, ct2.TransactionAmount
	    FROM	Sales.CustomerTransactions ct2
	    ORDER BY ct2.TransactionAmount DESC
	) q1 ON c.CustomerID = q1.CustomerID
ORDER BY TransactionAmount DESC


--	Через IN
SELECT		c.CustomerID
		,	c.CustomerName
		,	TransactionAmount
FROM		Sales.CustomerTransactions ct
	JOIN	Sales.Customers c ON ct.CustomerID = c.CustomerID
WHERE ct.CustomerTransactionID IN
								(
								    SELECT TOP 5 CustomerTransactionID
								    FROM Sales.CustomerTransactions ct2
								    ORDER BY ct2.TransactionAmount DESC
								)
ORDER BY TransactionAmount DESC

--	Через оконную функцию
SELECT		c.CustomerID
		,	c.CustomerName
		,	TransactionAmount
FROM    (
			SELECT		c.CustomerID
					,	ct.TransactionAmount
					,	ROW_NUMBER() OVER (ORDER BY ct.TransactionAmount DESC) AS [RN]
			FROM Sales.Customers c
			INNER JOIN Sales.CustomerTransactions ct ON c.CustomerID = ct.CustomerID
		) q1
JOIN	Sales.Customers c ON q1.CustomerID = c.CustomerID
WHERE q1.RN <= 5
ORDER BY TransactionAmount DESC
;

--	EXISTS
SELECT		c.CustomerID
		,	c.CustomerName
		,	TransactionAmount
FROM		Sales.CustomerTransactions ct
	JOIN	Sales.Customers c ON ct.CustomerID = c.CustomerID
WHERE EXISTS 
								(
									SELECT CustomerTransactionID		-- танцы с бубном, в противном случае выводит всех покупателей
									FROM	(
												SELECT TOP 5 CustomerTransactionID
												FROM Sales.CustomerTransactions 
												ORDER BY TransactionAmount DESC
											) ct2
											WHERE CT.CustomerTransactionID = ct2.CustomerTransactionID
								)
ORDER BY TransactionAmount DESC

-- CTE
WITH Transactions AS (
	SELECT	c.CustomerID
		,	ct.TransactionAmount
		,	ROW_NUMBER() OVER (ORDER BY ct.TransactionAmount DESC) AS [RN]
	FROM Sales.Customers c
	INNER JOIN Sales.CustomerTransactions ct ON c.CustomerID = ct.CustomerID
)
SELECT		c.CustomerID
		,	c.CustomerName
		,	TransactionAmount 
FROM Transactions q1
JOIN	Sales.Customers c ON q1.CustomerID = c.CustomerID
WHERE RN <= 5
ORDER BY TransactionAmount DESC
;


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

-- JOIN 
SELECT		c2.CityID
		,	c2.CityName
		,	p.FullName
	--	,	ws.UnitPrice 
	--	,	ws.StockItemID
FROM Sales.OrderLines ol
     JOIN Sales.Orders o ON ol.OrderID = o.OrderID					--	заказ
     JOIN Sales.Invoices i ON o.OrderID = i.OrderID					--	счет
     JOIN Sales.Customers c ON o.CustomerID = c.CustomerID			--	клиенты
     JOIN Application.Cities c2 ON c.DeliveryCityID = c2.CityID		--	город
     JOIN Application.People p ON i.PackedByPersonID = p.PersonID	--	люди формирующие
	 JOIN 
			(
			    SELECT TOP 3 si.StockItemID,UnitPrice -- выберем три дорогих товара
			    FROM		 Warehouse.StockItems si
			    ORDER BY	 si.UnitPrice DESC
			) SI ON SI.StockItemID = ol.StockItemID
	JOIN Warehouse.StockItems ws on ws.StockItemID = ol.StockItemID

-- WITH
WITH TopProducts AS (
						SELECT TOP 3 si.StockItemID
						FROM Warehouse.StockItems si
						ORDER BY si.UnitPrice DESC
					)
SELECT c2.CityID, c2.CityName, p.FullName
FROM Sales.OrderLines ol
     JOIN Sales.Orders o ON ol.OrderID = o.OrderID
     JOIN Sales.Invoices i ON o.OrderID = i.OrderID
     JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
     JOIN Application.Cities c2 ON c.DeliveryCityID = c2.CityID
     JOIN Application.People p ON i.PackedByPersonID = p.PersonID
WHERE ol.StockItemID IN (	SELECT tp.StockItemID 
							FROM TopProducts tp
						)

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос
SET STATISTICS IO, TIME ON;
--	Выбирает заказы с суммой более 27000 с указанием того что статус завершен и общей суммы отгруженых товаров 
SELECT 
		Invoices.InvoiceID
	,	Invoices.InvoiceDate
	,	(	
			SELECT People.FullName -- выберем продавца
			FROM Application.People
			WHERE People.PersonID = Invoices.SalespersonPersonID
		) AS SalesPersonName
	,	SalesTotals.TotalSumm AS TotalSummByInvoice	-- общая сумма счета (товар + накрутка ритейлера)
	,	(
			SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)  -- выберем общую сумму отгруженных товаров у которых статус завершен
			FROM Sales.OrderLines
			WHERE OrderLines.OrderId = (
										SELECT	Orders.OrderId 
										FROM	Sales.Orders
										WHERE	Orders.PickingCompletedWhen IS NOT NULL	
											AND Orders.OrderId = Invoices.OrderId
										)	
		) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN	--	Выберем счета на сумму товаров более 27 тысяч
		(	SELECT		InvoiceId	
					,	SUM(Quantity*UnitPrice) AS TotalSumm
			FROM		Sales.InvoiceLines
			GROUP BY InvoiceId
			HAVING	SUM(Quantity*UnitPrice) > 27000
		) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

/*
		ОПТИМИЗАЦИЯ
		Пойдем по пути выполнения оператора SELECT.
		1 FROM
		2 WHERE
		3 GROUP BY
		4 HAVING
		5 SELECT
		6 ORDER BY
		
		Вынесем все подзапросы за FROM
		Время ЦП уменьшилось в 2 раза
*/


--(затронуто строк: 8)
--Таблица "OrderLines". Число просмотров 8, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 690, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "OrderLines". Считано сегментов 1, пропущено 0.
--Таблица "InvoiceLines". Число просмотров 8, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 682, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "InvoiceLines". Считано сегментов 1, пропущено 0.
--Таблица "Orders". Число просмотров 5, логических чтений 725, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Invoices". Число просмотров 5, логических чтений 11994, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "People". Число просмотров 4, логических чтений 28, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--
-- Время работы SQL Server:
--   Время ЦП = 109 мс, затраченное время = 79 мс.
--
SET STATISTICS IO, TIME ON;
SELECT 
		Invoices.InvoiceID
	,	Invoices.InvoiceDate
	,	SalesTotals.TotalSumm AS TotalSummByInvoice	-- общая сумма счета (товар + накрутка ритейлера)
	,	TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN	(	SELECT		InvoiceId	--	Выберем счета на сумму товаров более 27 тысяч
						,	SUM(Quantity*UnitPrice) AS TotalSumm
				FROM		Sales.InvoiceLines
				GROUP BY InvoiceId
				HAVING	SUM(Quantity*UnitPrice) > 27000
			) AS SalesTotals ON Invoices.InvoiceID = SalesTotals.InvoiceID
	JOIN	Application.People AS People ON People.PersonID = Invoices.SalespersonPersonID
	JOIN	(
				SELECT	OL.OrderID,SUM(OL.PickedQuantity*OL.UnitPrice) TotalSummForPickedItems -- выберем общую сумму отгруженных товаров у которых статус завершен
				FROM Sales.OrderLines OL
				JOIN	(	SELECT	Orders.OrderId 
							FROM	Sales.Orders
							WHERE	Orders.PickingCompletedWhen IS NOT NULL	
						) O ON O.OrderId = OL.OrderId
				GROUP BY OL.OrderID
			)	AS O ON o.OrderID = Invoices.OrderID
ORDER BY TotalSumm DESC
;


--Время синтаксического анализа и компиляции SQL Server: 
-- время ЦП = 0 мс, истекшее время = 0 мс.
--
-- Время работы SQL Server:
--   Время ЦП = 0 мс, затраченное время = 0 мс.
--
--(затронуто строк: 8)
--Таблица "OrderLines". Число просмотров 2, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 345, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "OrderLines". Считано сегментов 1, пропущено 0.
--Таблица "InvoiceLines". Число просмотров 2, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 341, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "InvoiceLines". Считано сегментов 1, пропущено 0.
--Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Orders". Число просмотров 1, логических чтений 692, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Invoices". Число просмотров 1, логических чтений 11400, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--
-- Время работы SQL Server:
--   Время ЦП = 47 мс, затраченное время = 142 мс.
