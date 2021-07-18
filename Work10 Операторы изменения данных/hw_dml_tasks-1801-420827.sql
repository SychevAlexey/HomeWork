/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 

*/
--	создадим табличку копии
SELECT * 
		INTO [WideWorldImporters].[Application].[Countries3]
FROM [WideWorldImporters].[Application].[Countries2]

-- Инсерт
INSERT INTO [WideWorldImporters].[Application].[Countries3]
(	   [CountryID]
      ,[CountryName]
      ,[IsoAlpha3Code]
      ,[Iso]
	  )
SELECT  TOP 5 
		[CountryID]*-1 -- Ключик сделаем уникальным, дегко будет найти
      ,	[CountryName]
      ,	[IsoAlpha3Code]
      ,	[Iso]
  FROM [WideWorldImporters].[Application].[Countries3]

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE T1
-- SELECT *
FROM [WideWorldImporters].[Application].[Countries3] T1
WHERE t1.CountryID = (SELECT MIN(CountryID) FROM [WideWorldImporters].[Application].[Countries3])
					-- Вытащим минимальный ключик, все равно минусовые значения

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE T1
SET T1.CountryID = T1.CountryID*100 -- По тому же принципу изменим минимальный ключик
-- SELECT *
FROM [WideWorldImporters].[Application].[Countries3] T1
WHERE t1.CountryID = (SELECT MIN(CountryID) FROM [WideWorldImporters].[Application].[Countries3])

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/
--	создадим копию табилчки с новым клиентом
--DROP TABLE [WideWorldImporters].[Sales].[Customers_Archive_copy]
SELECT *
	INTO [WideWorldImporters].[Sales].[Customers_copy]
  FROM [WideWorldImporters].[Sales].[Customers]


-- Выделим 1 запись для корректировки
DROP TABLE IF EXISTS #TMP
SELECT TOP 1 *	
INTO #TMP
FROM [WideWorldImporters].[Sales].[Customers_copy]

--	SELECT * FROM #TMP
-- Создадим уникальный ключик
UPDATE #TMP	
SET CustomerID = 1062
,	BillToCustomerID = 1062
,	CustomerName = 'SAM SAM'
;
--	Втавляем наше рукоделие
INSERT INTO [WideWorldImporters].[Sales].[Customers_copy]
SELECT * FROM #TMP;
--	SELECT * FROM [WideWorldImporters].[Sales].[Customers_Archive_copy]
-- Сам MERGE

DROP TABLE IF EXISTS [WideWorldImporters].[Sales].[Customers1];
SELECT * -- сделал дубликат таблички, ругается на автоматическое создание каких полей, из 23 трудно выловить
	INTO [WideWorldImporters].[Sales].[Customers1]
  FROM [WideWorldImporters].[Sales].[Customers];



-- Выборка
MERGE [Sales].[Customers1] AS target
USING [Sales].[Customers_copy] AS SOURCE
	ON (target.[CustomerID] = Source.[CustomerID])
WHEN MATCHED AND YEAR(target.ValidFrom) = 2017 --Сделал невыполнимым условие, что бы отработал только инсерт
	THEN UPDATE
		SET [CustomerID] = Source.[CustomerID] 
WHEN NOT MATCHED
	THEN INSERT (
					[CustomerID] ,[CustomerName] ,[BillToCustomerID], [CustomerCategoryID],[BuyingGroupID],[PrimaryContactPersonID],[AlternateContactPersonID]
			      ,	[DeliveryMethodID],[DeliveryCityID],[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent]
			      ,	[IsOnCreditHold],[PaymentDays],[PhoneNumber],[FaxNumber],[DeliveryRun],[RunPosition],[WebsiteURL],[DeliveryAddressLine1],[DeliveryAddressLine2]
			      ,	[DeliveryPostalCode],[DeliveryLocation],[PostalAddressLine1],[PostalAddressLine2],[PostalPostalCode],[LastEditedBy],[ValidFrom],[ValidTo]	
				)
				VALUES
				(
					 Source.[CustomerID] ,Source.[CustomerName] ,Source.[BillToCustomerID], Source.[CustomerCategoryID],Source.[BuyingGroupID]
					,Source.[PrimaryContactPersonID],Source.[AlternateContactPersonID],	Source.[DeliveryMethodID],Source.[DeliveryCityID]
					,Source.[PostalCityID],Source.[CreditLimit],Source.[AccountOpenedDate],Source.[StandardDiscountPercentage],Source.[IsStatementSent]
					,Source.[IsOnCreditHold],Source.[PaymentDays],Source.[PhoneNumber],Source.[FaxNumber],Source.[DeliveryRun],Source.[RunPosition]
					,Source.[WebsiteURL],Source.[DeliveryAddressLine1],Source.[DeliveryAddressLine2],Source.[DeliveryPostalCode],Source.[DeliveryLocation]
					,Source.[PostalAddressLine1],Source.[PostalAddressLine2],Source.[PostalPostalCode],Source.[LastEditedBy],Source.[ValidFrom],Source.[ValidTo]	
				)
OUTPUT DELETED.[CustomerID],DELETED.[CustomerName],$ACTION,INSERTED.[CustomerID],INSERTED.[CustomerName];
/*
CustomerID	CustomerName	$ACTION	CustomerID	CustomerName
NULL	NULL	INSERT	1062	SAM SAM
*/


/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/
-- Создадим табличку исходник -- [Application].[Countries2]
CREATE TABLE [Application].[Countries4](
	[CountryID] [int] NOT NULL,
	[CountryName] [nvarchar](60) NOT NULL,
	[IsoAlpha3Code] [nvarchar](3) NULL,
	[Iso] [varchar](6) NULL
) ON [USERDATA]
------------ Вызов исполняемого файла CMD									Выгрузка	файлик					разделитель сервер откуда тащим
exec master..xp_cmdshell 'bcp "[WideWorldImporters].[Application].[Countries2]" out  "D:Countries2.txt" -T -w -t"@&#" -S DESKTOP-ROCJSCE\FLYZIG'

BULK INSERT [WideWorldImporters].[Application].[Countries4]
				   FROM "D:Countries2.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = '@&#',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );
SELECT TOP 5 * FROM [WideWorldImporters].[Application].[Countries4]
/*
CountryID	CountryName	IsoAlpha3Code	Iso
1	Afghanistan	AFG	4
3	Albania	ALB	8
4	Algeria	DZA	12
6	Andorra	AND	20
7	Angola	AGO	24
*/