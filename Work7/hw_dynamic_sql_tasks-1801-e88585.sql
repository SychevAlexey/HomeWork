/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/
--	Возьмем скрипт из прошлого задания уберем ограничения на 6 записей, выберем все. Зальем во временную табличку, в противном случае экранировать много
USE [WideWorldImporters]
     SELECT
	 /*Поставим формат dd/MM/yyyy*/
		FORMAT(CAST
				(CAST
					(YEAR(I.InvoiceDate) AS VARCHAR(4))	
					+'/'+
						CAST(DATEPART(MONTH,I.InvoiceDate) AS varchar(2))	
							+'/'+
								'1' AS DATE
				),'dd/MM/yyyy','en-Us'
			) D
		/* Уберем наименование поставщика из имени клинта Tailspin Toys,Wingtip Toys  */
        ,REPLACE(
					REPLACE(
							REPLACE(C.CustomerName,'Tailspin Toys (','')
																		,'Wingtip Toys (','')
																							,')','') AS CL
         ,COUNT(I.InvoiceID) AS QNTY
INTO #TMP -- вытащим все во временную табличку 
     FROM Sales.Customers AS C
     INNER JOIN Sales.Invoices AS I
          ON I.CustomerID = C.CustomerID
	 GROUP BY	FORMAT(CAST(CAST(YEAR(I.InvoiceDate) AS VARCHAR(4))	+'/'+CAST(DATEPART(MONTH,I.InvoiceDate) AS varchar(2))+'/'+'1' AS DATE),'dd/MM/yyyy','en-Us'),
				CAST(CAST(YEAR(I.InvoiceDate) AS VARCHAR(4))+'/'+CAST(DATEPART(MONTH,I.InvoiceDate) AS varchar(2))+'/'+'1' AS DATE)
		    ,	REPLACE(
					REPLACE(
							REPLACE(C.CustomerName,'Tailspin Toys (','')
																		,'Wingtip Toys (','')
																							 ,')','') 
ORDER BY FORMAT(CAST
				(CAST
					(YEAR(I.InvoiceDate) AS VARCHAR(4))	
					+'/'+
						CAST(DATEPART(MONTH,I.InvoiceDate) AS varchar(2))	
							+'/'+
								'1' AS DATE
				),'dd/MM/yyyy','en-Us'
			)

/*	Создаем переменные	
*/
DECLARE @dml AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)
 
SELECT @ColumnName= ISNULL(@ColumnName + ',','')  -- создадим строку с разделителями
       + QUOTENAME(CL) 
FROM (SELECT DISTINCT CL
         FROM #TMP
    GROUP BY CL
	) AS GRP

--SELECT @ColumnName as ColumnName /*Проверочка*/

/* Собираем динамический запрос
*/
SET @dml = 
  N'SELECT [DATE], ' +@ColumnName + ' FROM ----дата, имена клиентов
  (
  SELECT D AS [DATE],CL,SUM(QNTY) AS TOTAL
   FROM #TMP
    GROUP BY D,CL
   ) AS T
    PIVOT(SUM(TOTAL) 
           FOR CL IN (' + @ColumnName + ')) AS PVTTable
	ORDER BY [DATE]'


EXEC sp_executesql @dml

