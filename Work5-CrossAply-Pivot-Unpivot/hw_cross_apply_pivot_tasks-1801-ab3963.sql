/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

SELECT	D AS MONTH_SALES
	,	ISNULL([Gasport, NY],0)			AS [Gasport, NY]
	,	ISNULL([Jessie, ND],0)			AS [Jessie, ND]
	,	ISNULL([Medicine Lodge, KS],0)	AS [Medicine Lodge, KS]
	,	ISNULL([Peeples Valley, AZ],0)	AS [Peeples Valley, AZ]
	,	ISNULL([Sylvanite, MT],0)		AS [Sylvanite, MT]
	,	ISNULL([Gasport, NY],0)
		+ ISNULL([Jessie, ND],0) 
		+ ISNULL([Medicine Lodge, KS],0) 
		+ ISNULL([Peeples Valley, AZ],0) 
		+ ISNULL([Sylvanite, MT],0)		AS QNTY_MONTH
FROM
(
     SELECT
		 FORMAT(CAST
					(CAST
						(YEAR(I.InvoiceDate) AS VARCHAR(4))	
						+'/'+
							CAST(DATEPART(MONTH,I.InvoiceDate) AS varchar(2))	
								+'/'+
									'1' AS DATE
					),'dd/MM/yyyy','en-Us'
				) D
         ,REPLACE(
					REPLACE(C.CustomerName,'Tailspin Toys (','')
					,')','') AS CL
         , COUNT(I.InvoiceID) AS QNTY
     FROM Sales.Customers AS C
     INNER JOIN Sales.Invoices AS I
          ON I.CustomerID = C.CustomerID
     WHERE C.CustomerID BETWEEN 2 AND 6
	 GROUP BY	FORMAT(CAST(CAST(YEAR(I.InvoiceDate) AS VARCHAR(4))	+'/'+CAST(DATEPART(MONTH,I.InvoiceDate) AS varchar(2))+'/'+'1' AS DATE),'dd/MM/yyyy','en-Us')
			,	CAST(CAST(YEAR(I.InvoiceDate) AS VARCHAR(4))+'/'+CAST(DATEPART(MONTH,I.InvoiceDate) AS varchar(2))+'/'+'1' AS DATE)
		    ,	REPLACE(REPLACE(C.CustomerName,'Tailspin Toys (',''),')','')
--ORDER BY D
) AS SALES
PIVOT (SUM(QNTY)
		FOR CL IN ([Gasport, NY],[Jessie, ND],[Medicine Lodge, KS],[Peeples Valley, AZ],[Sylvanite, MT])
		)	AS PVT
ORDER BY CAST(D AS DATE)
-----------------------------

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT	DISTINCT
		CustomerName
	,	ADRESS
FROM 
	(
		SELECT	sc.CustomerName
			,	sc.DeliveryAddressLine1
			,	sc.DeliveryAddressLine2
			,	sc.PostalAddressLine1
			,	sc.PostalAddressLine2
		FROM Sales.Customers sc
					WHERE CustomerName LIKE 'Tailspin Toys%'
	) AS ad
UNPIVOT (ADRESS FOR CustomerID IN (
										DeliveryAddressLine1
									,	DeliveryAddressLine2
									,	PostalAddressLine1
									,	PostalAddressLine2
									)
		) AS UNP

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT	CountryID
	,	CountryName
	,	Code
FROM (
		SELECT	CountryID
			,	CountryName
			,	CAST(IsoAlpha3Code AS varchar(6))	Alpha3Code
			,	CAST(IsoNumericCode AS varchar(6))  NumericCode
		FROM Application.Countries
	) AS F
UNPIVOT (CODE FOR FormalName IN (		Alpha3Code
									,	NumericCode
								)) AS UNP

--EXEC SP_HELP'Application.Countries'
/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
/* Немного не понятно, товар может повторятся или нет. 
	Сделал 2 варианта:
1. Сделал 2 самые дорогие покупки на дату: (второй ниже)
*/
SELECT	OSN.CustomerID		AS ИдКлиента
	,	CUS.CustomerName	AS НаименованиеКлиента
	,	OSN.StockItemID		AS ИдТовара
	,	ST.StockItemName	AS НаименованиеТовара
	,	OSN.SUMMA			AS СуммаТовара
	,	OSN.OrderDate		AS ДатаПокупки
FROM 
	(
		SELECT			i.CustomerID
					,	ol.StockItemID
					,	O.OrderDate
					,	ol.UnitPrice as SUMMA
					,	ROW_NUMBER() OVER (partition by i.CustomerID ORDER BY ol.UnitPrice desc) AS RN
		FROM Sales.Invoices i
			JOIN Sales.InvoiceLines IL ON IL.InvoiceID = i.InvoiceID
			JOIN Sales.Orders o on i.OrderID = o.OrderID
			JOIN Sales.OrderLines ol on o.OrderID = ol.OrderID
		--WHERE I.CustomerID = 2
		GROUP BY	i.CustomerID
				,	ol.StockItemID
				,	O.OrderDate
				,	ol.UnitPrice
	)	OSN
	CROSS APPLY
		(SELECT StockItemID,StockItemName FROM Warehouse.StockItems ST
			WHERE OSN.StockItemID = ST.StockItemID
		) ST
	CROSS APPLY
		(SELECT CustomerID,CustomerName FROM Sales.Customers CUS
			WHERE CUS.CustomerID = OSN.CustomerID
		) CUS
WHERE RN<=2

/*	2. Два товара по максимальной цене покупавшяся первый раз когда ни будь.
*/
SELECT	OSN.CustomerID		AS ИдКлиента
	,	CUS.CustomerName	AS НаименованиеКлиента
	,	OSN.StockItemID		AS ИдТовара
	,	ST.StockItemName	AS НаименованиеТовара
	,	OSN.SUMMA			AS СуммаТовара
	,	OSN.DATEM			AS ДатаПокупки
FROM 
	(
		SELECT			i.CustomerID
					,	ol.StockItemID
					,	MAX(i.InvoiceDate) DATEM
					,	ol.UnitPrice as SUMMA
					,	ROW_NUMBER() OVER (partition by i.CustomerID ORDER BY ol.UnitPrice desc) AS RN
		FROM Sales.Invoices i
			JOIN Sales.InvoiceLines IL ON IL.InvoiceID = i.InvoiceID
			JOIN Sales.Orders o on i.OrderID = o.OrderID
			JOIN Sales.OrderLines ol on o.OrderID = ol.OrderID
		--WHERE I.CustomerID = 2
		GROUP BY	i.CustomerID
				--,	i.InvoiceID
				,	ol.StockItemID
				,	ol.UnitPrice
	)	OSN
	CROSS APPLY
		(SELECT StockItemID,StockItemName FROM Warehouse.StockItems ST
			WHERE OSN.StockItemID = ST.StockItemID
		) ST
	CROSS APPLY
		(SELECT CustomerID,CustomerName FROM Sales.Customers CUS
			WHERE CUS.CustomerID = OSN.CustomerID
		) CUS
WHERE RN<=2