/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Опционально - если вы знакомы с insert, update, merge, то загрузить эти данные в таблицу Warehouse.StockItems.
Существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 
Время
-1.01
-1.08
*/

------------------------------------------------------------

DECLARE @x XML
SET @x = (SELECT * FROM OPENROWSET  (BULK 'D:\StockItems.xml', SINGLE_BLOB)  as d)

SELECT 
[Name] = t.Item.value('@Name', 'nvarchar(100)'),
[SupplierID] = t.Item.value('SupplierID[1]', 'int'),
[UnitPackageID] = t.Item.value('Package[1]/UnitPackageID[1]', 'int'),
[OuterPackageID] = t.Item.value('Package[1]/OuterPackageID[1]', 'int'),
[QuantityPerOuter] = t.Item.value('Package[1]/QuantityPerOuter[1]', 'int'),
[TypicalWeightPerUnit] = t.Item.value('Package[1]/TypicalWeightPerUnit[1]', 'decimal(18,3)'),
[LeadTimeDays] = t.Item.value('LeadTimeDays[1]', 'int'),
[IsChillerStock] = t.Item.value('IsChillerStock[1]', 'bit'),
[TaxRate] = t.Item.value('TaxRate[1]', 'decimal(18,3)'),
[UnitPrice] = t.Item.value('UnitPrice[1]','decimal(18,2)')
 FROM @x.nodes('StockItems/Item') as t(Item)


 

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
-FOR XML-
*/
--	Работающий запрос ниже

declare @cmd_xml varchar(8000)
set @cmd_xml= 'bcp "SELECT * FROM [DESKTOP-ROCJSCE\FLYZIG].WideWorldImporters.[Warehouse].[StockItems] FOR XML PATH" queryout "d:\TEST\StockItems2.xml" -T -q -w -e'
exec xp_cmdshell @cmd_xml, no_output
/*
	Непонятная штука, потратил много времени на выяснение причины, так и не нашел
	-	Сетевой доступ открыт (в конфигураторе TCP/IP)
	-	Баловался с правами на пользователя. почти все дал
	-	обновил версию BCP до 15
	-	Драйвер ODBC стоит новый
*/
--	Вывод ошибок 
--SQLState = 08001, NativeError = 2
--Error = [Microsoft][ODBC Driver 13 for SQL Server]Поставщик именованных каналов: Не удалось открыть соединение с SQL Server [2]. 
--SQLState = 08001, NativeError = 2
--Error = [Microsoft][ODBC Driver 13 for SQL Server]При установлении соединения с сервером SQL Server произошла ошибка, связанная с сетью или с определенным экземпляром. Сервер не найден или недоступен. Убедитесь, что имя экземпляра указано правильно и на с
--ервере SQL Server разрешены удаленные соединения. Дополнительные сведения см. в электронной документации по SQL Server.
--SQLState = S1T00, NativeError = 0
--Error = [Microsoft][ODBC Driver 13 for SQL Server]Время ожидания входа в систему истекло.

-- сам по себе запрос работает, по видимому какие то неприятности с програмкой BCP
select 
		 [StockItemName] AS [@Name]
		,[SupplierID] AS [SupplierID]
		,[UnitPackageID] AS [Package/UnitPackageID]
		,[OuterPackageID] AS [Package/OuterPackageID]
		,[QuantityPerOuter] AS [Package/QuantityPerOuter]
		,[TypicalWeightPerUnit] AS [Package/TypicalWeightPerUnit]
		,[LeadTimeDays] AS [LeadTimeDays]
		,[IsChillerStock] AS [IsChillerStock]
		,[TaxRate] AS [TaxRate]
		,[UnitPrice] AS [UnitPrice]
from [DESKTOP-ROCJSCE\FLYZIG].WideWorldImporters.[Warehouse].[StockItems] FOR XML PATH('Item'),ROOT('StockItems')
																			--	закрывающий тэг / элемент верхнего уровня

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
Время видео
-0.52
0.56
-0.08
1.24
*/

SELECT StockItemID, 
       StockItemName, 
       JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS [CountryOfManufacture], 
       JSON_VALUE(CustomFields, '$.Tags[0]') AS Tags
FROM Warehouse.StockItems
;

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле
Время-23.40
Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

SELECT si.*
FROM [Warehouse].[StockItems] si
CROSS APPLY OPENJSON(CustomFields, '$.Tags')
WHERE Value = 'Vintage';