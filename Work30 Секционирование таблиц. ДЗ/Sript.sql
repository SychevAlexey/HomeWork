/*	так как в проекте нет подходящих таблиц для секционирования, буду дробить [WideWorldImporters].[Warehouse].[StockItemTransactions]
	Выбираем ключ для секционирования [StockItemTransactionID] тип INT, так как это поле используется во всех запросах
*/

ALTER DATABASE [WideWorldImporters] ADD FILEGROUP StockItemTransaction
GO

--добавляем файл БД (Создаем базу)
ALTER DATABASE [WideWorldImporters] ADD FILE 
( NAME = N'Transact', FILENAME = N'D:\OUT\mssql\Transact.ndf' , 
SIZE = 1097152KB , FILEGROWTH = 65536KB ) TO FILEGROUP StockItemTransaction
GO

--создаем функцию партиционирования по годам - по умолчанию left!!
CREATE PARTITION FUNCTION [fn_StockItemTransaction](INT) AS RANGE RIGHT FOR VALUES
(1,100000,200000,300000,40000);																																																									
GO

-- партиционируем, используя созданную нами функцию
CREATE PARTITION SCHEME [schm_StockItemTransaction] AS PARTITION [fn_StockItemTransaction] 
ALL TO (StockItemTransaction)
GO

--создаем наши секционированные таблицы
--DROP TABLE Warehouse.StockItemTransactions_Partitioned;

CREATE TABLE Warehouse.StockItemTransactions_Partitioned(
	[StockItemTransactionID] [int] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[TransactionTypeID] [int] NOT NULL,
	[CustomerID] [int] NULL,
	[InvoiceID] [int] NULL,
	[SupplierID] [int] NULL,
	[PurchaseOrderID] [int] NULL,
	[TransactionOccurredWhen] [datetime2](7) NOT NULL,
	[Quantity] [decimal](18, 3) NOT NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
) ON schm_StockItemTransaction([StockItemTransactionID])---в схеме [schm_StockItemTransaction] по ключу [StockItemTransactionID]
GO

--создадим кластерный индекс в той же схеме с тем же ключом
ALTER TABLE Warehouse.StockItemTransactions_Partitioned ADD CONSTRAINT PK_StockItemTransactions_Partitioned
PRIMARY KEY CLUSTERED  ([StockItemTransactionID])
 ON [schm_StockItemTransaction](StockItemTransactionID);

 /*		Выгрузим данные на диск, для иморта в табличку с секционированием
 */
SELECT @@SERVERNAME
--

exec master..xp_cmdshell 'bcp "SELECT * FROM [WideWorldImporters].[Warehouse].[StockItemTransactions]" queryout "d:\OUT\mssql\StockItemTransactions_Partitioned.txt" -T -w -t "@eu&$" -S DESKTOP-ROCJSCE\FLYZIG'

/*		зальем данные в нашу партиционированные таблицы
*/
DECLARE 
	@path VARCHAR(256),
	@FileName VARCHAR(256),
	@onlyScript BIT, 
	@query	nVARCHAR(MAX),
	@dbname VARCHAR(255),
	@batchsize INT
	
	SELECT @dbname = DB_NAME();
	SET @batchsize = 1000;

	/*******************************************************************/
	/*******************************************************************/
	/******Change for path and file name*******************************/
	SET @path = 'd:\OUT\mssql\';
	SET @FileName = 'StockItemTransactions_Partitioned.txt';
	/*******************************************************************/
	/*******************************************************************/
	/*******************************************************************/

	SET @onlyScript = 0;
	
	BEGIN TRY

		IF @FileName IS NOT NULL
		BEGIN
			SET @query = 'BULK INSERT ['+@dbname+'].[Warehouse].[StockItemTransactions_Partitioned]
				   FROM "'+@path+@FileName+'"
				   WITH 
					 (
						BATCHSIZE = '+CAST(@batchsize AS VARCHAR(255))+', 
						DATAFILETYPE = ''widechar'',
						FIELDTERMINATOR = ''@eu&$'',
						ROWTERMINATOR =''\n'',
						KEEPNULLS,
						TABLOCK        
					  );'

			PRINT @query

			IF @onlyScript = 0
				EXEC sp_executesql @query 
			PRINT 'Bulk insert '+@FileName+' is done, current time '+CONVERT(VARCHAR, GETUTCDATE(),120);
		END;
	END TRY

	BEGIN CATCH
		SELECT   
			ERROR_NUMBER() AS ErrorNumber  
			,ERROR_MESSAGE() AS ErrorMessage; 

		PRINT 'ERROR in Bulk insert '+@FileName+' , current time '+CONVERT(VARCHAR, GETUTCDATE(),120);

	END CATCH
--Bulk insert StockItemTransactions_Partitioned.txt is done, current time 2021-08-15 11:05:30

-- Проверяем табличку
select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1
/*----		RESULT------------------
CustomerTransactions
StockItemTransactions_Partitioned
SupplierTransactions
---------------------------------*/

SELECT  $PARTITION.[fn_StockItemTransaction]([StockItemTransactionID]) AS Partition
		, COUNT(*) AS [COUNT]
		, MIN([StockItemTransactionID]) MIN_
		,MAX([StockItemTransactionID]) MAX_
FROM Warehouse.StockItemTransactions_Partitioned
GROUP BY $PARTITION.[fn_StockItemTransaction]([StockItemTransactionID]) 
ORDER BY Partition ; 
 
/*		RESULT	

Partition	COUNT	MIN_	MAX_
2	28317	1	39999
3	42340	40000	99999
4	70469	100000	199999
5	70143	200001	299999
6	25398	300000	336251

*/