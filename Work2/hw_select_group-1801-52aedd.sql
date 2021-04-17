/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/
SELECT	StockItemID,StockItemName
FROM	[Warehouse].[StockItems]
WHERE	StockItemName LIKE 'Animal%'
	OR	StockItemName LIKE '%urgent%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT	DISTINCT	T1.SupplierName
FROM				Purchasing.Suppliers T1
		LEFT JOIN	Purchasing.PurchaseOrders T2 ON	T1.SupplierID = T2.SupplierID
WHERE				T2.PurchaseOrderID IS NULL
ORDER BY			T1.SupplierName


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)


Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/
SELECT			O.OrderID								AS Заказ
			,	FORMAT(O.OrderDate, 'd', 'en-gb')		AS ДатаЗаказа
			,	FORMAT(O.OrderDate, 'MMMM', 'ru-ru')	AS МесяцЗаказа
			,	DATEPART(QUARTER, O.OrderDate)			AS Квартал
			,	CASE	WHEN DATEPART(M, O.OrderDate) BETWEEN 1 AND 4	THEN 1
						WHEN DATEPART(M, O.OrderDate) BETWEEN 5 AND 8	THEN 2
						WHEN DATEPART(M, O.OrderDate) BETWEEN 9 AND 12	THEN 3
				END										AS Треть
			,	cus.CustomerName
			,	OL.UnitPrice AS [Цена]
			,	OL.Quantity AS [Количество]
FROM	Sales.Orders AS O
	JOIN Sales.Customers cus ON cus.CustomerID = o.CustomerID
	JOIN Sales.OrderLines AS OL ON OL.OrderID=O.OrderID
WHERE O.PickingCompletedWhen IS NOT NULL 
	AND 
		(
			OL.UnitPrice > 100 OR OL.Quantity > 20
		)
ORDER BY	DATEPART(QUARTER, O.OrderDate)	
		,	CASE	WHEN DATEPART(M, O.OrderDate) BETWEEN 1 AND 4	THEN 1
					WHEN DATEPART(M, O.OrderDate) BETWEEN 5 AND 8	THEN 2
					WHEN DATEPART(M, O.OrderDate) BETWEEN 9 AND 12	THEN 3
			END	
		,	FORMAT(O.OrderDate, 'd', 'en-gb')
--		ИЛИ по ORDER BY 4,5,2
/*
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.
*/
SELECT			O.OrderID								AS Заказ
			,	FORMAT(O.OrderDate, 'd', 'en-gb')		AS ДатаЗаказа
			,	FORMAT(O.OrderDate, 'MMMM', 'ru-ru')	AS МесяцЗаказа
			,	DATEPART(QUARTER, O.OrderDate)			AS Квартал
			,	CASE	WHEN DATEPART(M, O.OrderDate) BETWEEN 1 AND 4	THEN 1
						WHEN DATEPART(M, O.OrderDate) BETWEEN 5 AND 8	THEN 2
						WHEN DATEPART(M, O.OrderDate) BETWEEN 9 AND 12	THEN 3
				END										AS Треть
			,	cus.CustomerName
			,	OL.UnitPrice AS [Цена]
			,	OL.Quantity AS [Количество]
FROM	Sales.Orders AS O
	JOIN Sales.Customers cus ON cus.CustomerID = o.CustomerID
	JOIN Sales.OrderLines AS OL ON OL.OrderID=O.OrderID
WHERE O.PickingCompletedWhen IS NOT NULL 
	AND (
			OL.UnitPrice > 100 OR OL.Quantity > 20
		)
ORDER BY 4,5,2
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT		DM.DeliveryMethodName		AS	МетодДоставки
		,	PO.ExpectedDeliveryDate		AS	ДатаВыполнения
		,	S.SupplierName				AS	Поставщик
		,	P.FullName					AS	КонтактноеЛицо
FROM		Purchasing.PurchaseOrders	AS	PO
		JOIN Application.DeliveryMethods AS DM ON PO.DeliveryMethodID = DM.DeliveryMethodID 
			AND DM.DeliveryMethodName IN	(
												'Air Freight'
											,	'Refrigerated Air Freight'
											)
		JOIN Purchasing.Suppliers AS S ON S.SupplierID = PO.SupplierID
		JOIN Application.People AS P ON P.PersonID = PO.ContactPersonID
		JOIN Purchasing.SupplierTransactions AS ST ON ST.PurchaseOrderID = PO.PurchaseOrderID
WHERE	YEAR(PO.ExpectedDeliveryDate)	= 2013
	AND MONTH(PO.ExpectedDeliveryDate)	= 1
order by 2

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10	Customer.CustomerName	AS Клиент
			,	Salesperson.FullName	AS Продавец
			,	O.OrderDate
FROM		Sales.Orders AS O
		JOIN Sales.Customers AS Customer ON Customer.CustomerID = O.CustomerID
		JOIN Application.People AS Salesperson ON Salesperson.PersonID = O.SalespersonPersonID
ORDER BY O.OrderDate DESC


/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT DISTINCT		C.CustomerID	AS КодКлиента
				,	C.CustomerName	AS ИмяКлиента
				,	C.PhoneNumber	AS НомерКлиента
FROM		Warehouse.StockItems AS I
		JOIN Sales.OrderLines AS OL ON OL.StockItemID = I.StockItemID
		JOIN Sales.Orders AS O ON O.OrderID = OL.OrderID
		JOIN Sales.Customers AS C ON C.CustomerID = O.CustomerID
WHERE I.StockItemName='Chocolate frogs 250g' 

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам (Это за все товары в среднем или по уникальноститоваров?)
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
--
Не совсем понятно что входит в поле UnitPrice и в поле Quantity 
Взял пример по счету InvoiceID=55519

SELECT 'Sales.Invoices',	* FROM Sales.Invoices AS I	where 	InvoiceID=55519
SELECT 'Sales.Orders',	* FROM Sales.Orders AS O where OrderID = 57867
SELECT 'Sales.OrderLines',* FROM Sales.OrderLines AS OL where OrderID = 57867
SELECT 'CustomerTransactions',* FROM [WideWorldImporters].[Sales].[CustomerTransactions] WHERE InvoiceID=55519

По выставленному счету InvoiceID=55519
						  ордер =57867
				Входящие суммы по ордеру 240+13+13+13+25 = 304
		Транзакция на 0плату =	2599
Значит по этой покупке сумма будет (9*240)+(10*13)+(9*13)+(9*13)+(3*25)=2599

*/

SELECT	MONTH_ID.YEAR_N				AS	Год
	,	MONTH_ID.MONTH_N			AS	Месяц
	,	SUMM_GRP.ОбщКоличТоваров	AS	ОбКолТ
	,	SUMM_GRP.ОбщаяПродажаЗаМес	AS	ОбПрЗаМес
	,	SUMM_GRP.СрЧек
	,	Invoice						AS	КоличЗак
	,	SR_TOV.SR_TOV				AS	СрЦенаЗа1ТовЗаМес
FROM 
	(
		/*Сделаем табличку с периодами*/
		SELECT		YEAR(InvoiceDate)*100+MONTH(InvoiceDate)	AS	MONTH_ID
				,	YEAR(InvoiceDate)							AS	YEAR_N
				,	MONTH(InvoiceDate)							AS	MONTH_N
				,	SUM(1)										AS	Invoice --количество заказов
		FROM		Sales.Invoices 
		GROUP BY	YEAR(InvoiceDate)*100+MONTH(InvoiceDate) 
				,	YEAR(InvoiceDate)							
				,	MONTH(InvoiceDate)
	)	MONTH_ID
		LEFT	JOIN (
							SELECT			YEAR(InvoiceDate)*100+MONTH(InvoiceDate)	AS	MONTH_ID
										,	CAST(ROUND(SUM(QNTY),0) AS FLOAT)			AS	ОбщКоличТоваров								
										,	CAST(ROUND(SUM(UP),0) AS FLOAT)				AS	ОбщаяПродажаЗаМес
										,	CAST(ROUND(AVG(UP),0) AS FLOAT)				AS	СрЧек
							FROM	Sales.Invoices AS I													-- Выставленный счет
										JOIN Sales.Orders AS O ON I.OrderID=O.OrderID					-- Ордер
										JOIN (
												SELECT		OrderID,SUM(Quantity*UnitPrice) UP,sum(Quantity) QNTY--,AVG(UnitPrice/Quantity) SR--,AVG(UnitPrice) PRD
												--INTO #TMP		посчитаем общую сумму заказа / Просуммируем количество / 
												FROM		Sales.OrderLines
												--WHERE		OrderID = 57867
												GROUP BY	OrderID
												) AS OL ON OL.OrderID=O.OrderID					-- товар
							--WHERE	i.InvoiceID=55519
							GROUP BY		YEAR(InvoiceDate)*100+MONTH(InvoiceDate)
					) SUMM_GRP ON SUMM_GRP.MONTH_ID=MONTH_ID.MONTH_ID
		LEFT JOIN (
					SELECT		MONTH_ID
							,	AVG(SUMMA) SR_TOV --Сделаем среднее значение по уникальным товарам
					FROM	(
								SELECT		YEAR(InvoiceDate)*100+MONTH(InvoiceDate)	AS	MONTH_ID
										,	StockItemID				--	Выведем значение по товару
										,	AVG(SUMM)	AS SUMMA	--	В разных месяцах оно бывает разное, по этому смотрим по каждому товару в периоде
								FROM	Sales.Invoices AS I							-- Выставленный счет
									JOIN Sales.Orders AS O ON I.OrderID=O.OrderID	-- Ордер
									JOIN (
											SELECT			OrderID
														,	StockItemID
														,	AVG(UnitPrice) SUMM
											FROM		Sales.OrderLines
											--WHERE		OrderID = 57867
											GROUP BY	OrderID
														,	StockItemID
											) AS OL ON OL.OrderID=O.OrderID			-- товар
								GROUP BY	YEAR(InvoiceDate)*100+MONTH(InvoiceDate)
										,	StockItemID	
								--ORDER by 1,2
							)	SR_TOV
					GROUP BY	MONTH_ID
					) SR_TOV ON SR_TOV.MONTH_ID = MONTH_ID.MONTH_ID

/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

TODO: напишите здесь свое решение

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

TODO: напишите здесь свое решение

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
