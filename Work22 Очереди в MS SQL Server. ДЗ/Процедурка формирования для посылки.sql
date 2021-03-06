
/*		Запрос без процедурки
		
*/
  SELECT IST.[CustomerID]
		,GETDATE() Start_request
		,'20130101' +' - '+ '20130129' DATE_BETWEEN
		,IST.QNTY
		,MINIM.MIND
		,MAXIM.MAXD
  FROM 
   (
		SELECT [CustomerID],COUNT(OrderID) QNTY
		FROM [WideWorldImporters].[Sales].[Invoices]
		WHERE CustomerID = 803
					AND InvoiceDate BETWEEN '20130101' AND '20130129'
		GROUP BY [CustomerID]
	) IST
	LEFT JOIN (	SELECT	[CustomerID],MIN([InvoiceDate]) MIND
				FROM	[WideWorldImporters].[Sales].[Invoices]
				WHERE CustomerID = 803
					AND InvoiceDate BETWEEN '20130101' AND '20130129'
				GROUP BY [CustomerID]
		) MINIM ON MINIM.CustomerID = IST.CustomerID 
	LEFT JOIN (	SELECT	[CustomerID],MAX([InvoiceDate]) MAXD
				FROM	[WideWorldImporters].[Sales].[Invoices]
				WHERE CustomerID = 803
					AND InvoiceDate BETWEEN '20130101' AND '20130129'
				GROUP BY [CustomerID]
		) MAXIM ON MAXIM.CustomerID = IST.CustomerID
--------------------------------------------------------------------------------
--	CustomerID	Start_request			DATE_BETWEEN		QNTY	MIND	MAXD
--	803			2021-08-16 19:16:50.470	20130101 - 20130129	6	2013-01-01	2013-01-29

-----------------------------------------------------------------
--Start_request				CustomerID	DATE_BETWEEN	QNTY	MIND	MAXD
--2021-08-16 19:18:34.447	803	2013-01-01 - 2013-01-29	6	2013-01-01	2013-01-29


CREATE OR ALTER FUNCTION [Sales].[prc_Customers_reriod_New] (
																@CustomerID INT --	ключик покупателя
															,	@D_START DATE	--	период начало
															,	@D_END	DATE	--	период конец
															)
RETURNS TABLE
AS
	RETURN(	
		SELECT GETDATE() Start_request -- Момент Формарирование запроса
				,IST.[CustomerID]		 -- Покупатель
				,CAST(CAST(@D_START AS VARCHAR(35)) +' - ' + CAST(@D_END AS VARCHAR(35)) AS VARCHAR(80))	AS DATE_BETWEEN --вывод периода запроса
				,IST.QNTY				 -- Количество
				,MINIM.MIND				 -- Мин Дата
				,MAXIM.MAXD				 -- Макс Дата
		  FROM 
		   (
				SELECT	[CustomerID]
					,	COUNT(OrderID) QNTY -- Количество
				FROM [WideWorldImporters].[Sales].[Invoices]
				WHERE CustomerID = @CustomerID
							AND InvoiceDate BETWEEN @D_START 
												AND @D_END
				GROUP BY [CustomerID]
			) IST
			LEFT JOIN (	SELECT	 [CustomerID]	--Вытащим минимальную дата
							,MIN([InvoiceDate]) MIND
						FROM	[WideWorldImporters].[Sales].[Invoices]
						WHERE CustomerID = @CustomerID
							AND InvoiceDate BETWEEN @D_START 
												AND @D_END
						GROUP BY [CustomerID]
				) MINIM ON MINIM.CustomerID = IST.CustomerID 
			LEFT JOIN (	SELECT   [CustomerID]	--Вытащим максимальную дату
							,MAX([InvoiceDate]) MAXD
						FROM	[WideWorldImporters].[Sales].[Invoices]
						WHERE CustomerID = @CustomerID
							AND InvoiceDate BETWEEN @D_START 
												AND @D_END
						GROUP BY [CustomerID]
				) MAXIM ON MAXIM.CustomerID = IST.CustomerID
	);

--EXEC [Sales].[prc_Customers_reriod] 803,'20130101','20130129'

SELECT * 
--INTO [Sales].LOG_SEND
FROM [Sales].[prc_Customers_reriod_New](803,'20130101','20130129')

EXEC SP_HELP'[Sales].LOG_SEND'

