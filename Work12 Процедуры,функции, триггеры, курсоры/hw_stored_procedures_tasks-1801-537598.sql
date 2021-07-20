/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

ALTER FUNCTION Sales.PRC_CustomerId()
RETURNS INT
AS
BEGIN
DECLARE @CustometID INT;
WITH OrderAmount
 AS (
		SELECT		il.InvoiceID -- товар
				,	SUM(il.Quantity * ISNULL(il.UnitPrice,1)) AS Amount -- сумма
		FROM Sales.InvoiceLines il
		        INNER JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID
		GROUP BY il.InvoiceID
	)
SELECT TOP 1 @CustometID = c.CustomerID
FROM Sales.Invoices i
	JOIN OrderAmount oa ON i.InvoiceID = oa.InvoiceID
	JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
ORDER BY oa.Amount DESC;
RETURN @CustometID;
END;
GO

SELECT Sales.PRC_CustomerId();
--(Отсутствует имя столбца)
--834

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

CREATE PROCEDURE Sales.prcCustomers
@CustomerID INT = NULL 
AS   
    SET NOCOUNT ON;   
  
-- Проверка параметра @SalesPerson .  
IF @CustomerID IS NULL  
BEGIN  
   PRINT 'ERROR: EMPTY CUSTOMER'  
   RETURN  
END     
SELECT		CUSTOMERNAME
		,	IST.CustomerID
		,	Summa
FROM (
		SELECT		CustomerID
				,	SUM(il.Quantity * il.UnitPrice) Summa
		FROM Sales.InvoiceLines IL
			JOIN Sales.Invoices I ON IL.InvoiceID = I.InvoiceID
				WHERE I.CustomerID = @CustomerID
		GROUP BY CustomerID
	) IST 
		JOIN Sales.Customers C ON C.CustomerID = IST.CustomerID
		;
RETURN 
GO 

EXEC Sales.prcCustomers 834;
--CUSTOMERNAME	CustomerID	Summa
--Cong Hoa	834	331512.10

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

-- Сделаю без вывода фио
-- Процедурка
ALTER PROCEDURE Sales.prc_GetCustomer @CustomerID INT
AS
BEGIN
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SELECT @CustomerId AS [CustomerId], 
        (
        SELECT SUM(il.Quantity * il.UnitPrice)
            FROM Sales.InvoiceLines il 
                INNER JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID 
            WHERE i.CustomerID = @CustomerID
        ) AS Total;
    END;
GO

EXEC Sales.prc_GetCustomer 834
/*
CustomerId	Total
834	331512.10
*/

--	Функция
ALTER FUNCTION Sales.f_GetCustomer (@CustomerId INT)
RETURNS MONEY
AS
    BEGIN
        RETURN
        (
            SELECT SUM(il.Quantity * il.UnitPrice)
            FROM Sales.InvoiceLines il
                INNER JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID
            WHERE i.CustomerID = @CustomerID
        );
    END;
GO

SELECT Sales.f_GetCustomer(834)

SET STATISTICS IO ON 
EXEC Sales.prc_GetCustomer 834;
SELECT Sales.f_GetCustomer(834);

------------------------------------------
Таблица "InvoiceLines". Число просмотров 2, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 341, lob физических чтений 0, lob упреждающих чтений 0.
Таблица "InvoiceLines". Считано сегментов 1, пропущено 0.
Таблица "Invoices". Число просмотров 1, логических чтений 2, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
/*	Процедура отрабатывает медленнее, ЧИсло просмотров больше и логических чтений у нее 341, а функции 0
	По плану запроса у процедуры большая многоходовочка агрегаты хеш мач, поиск не в кластеризованном индексе и просмотрт индекса
	Процедура - стоимость по отношению к пакету 100%
	Функция   - стоимость по отношению к пакету 0%

*/


/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/
-- три последних заказа
CREATE FUNCTION Sales.f_PackedInvoices(@PersonId INT)
RETURNS TABLE
AS
	RETURN(	
		SELECT TOP 3 i.InvoiceID
		FROM Sales.Invoices i
		WHERE i.PackedByPersonID = @PersonId
		ORDER BY i.InvoiceID, i.InvoiceDate DESC
	);
GO
-- подтянем через кросс
SELECT p.PersonID, p.FullName, TopInvoices.InvoiceId
FROM Application.People p
CROSS APPLY (
	SELECT ti.InvoiceId
	FROM Sales.f_PackedInvoices(p.PersonId) ti
) AS TopInvoices
WHERE p.IsEmployee = 1

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
Использовал бы SERIALIZABLE - минимальный уровень изоляции ставящий блокировки на UPDATE, INSERT, DELETE, да, медленней будет работать, но гарантированный результат :)