SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--��������� ����������� �������� ������� � ������� �������
CREATE OR ALTER PROCEDURE Sales.SendNewInvoice2
						@CustomerID INT --	������ ����������
					,	@D_START DATE	--	������ ������
					,	@D_END	DATE	--	������ �����
AS
BEGIN
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER; --open init dialog
	DECLARE @RequestMessage NVARCHAR(4000); --���������, ������� ����� ����������
	
	BEGIN TRAN --�������� ����������

	--Prepare the Message  !!!auto generate XML
--	SELECT @RequestMessage = (SELECT InvoiceID
--							  FROM Sales.Invoices AS Inv
--							  WHERE InvoiceID = @invoiceId
--							  FOR XML AUTO, root('RequestMessage')); 

	SELECT @RequestMessage = (SELECT	Start_request
									,	CustomerID
									,	DATE_BETWEEN
									,	QNTY
									,	MIND
									,	MAXD
							  FROM [Sales].[prc_Customers_reriod_New](@CustomerID,@D_START,@D_END)
							  FOR XML PATH('prc'), root('RequestMessage')); 

	
	--Determine the Initiator Service, Target Service and the Contract 
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//WWI/SB/InitiatorService]
	TO SERVICE
	'//WWI/SB/TargetService'
	ON CONTRACT
	[//WWI/SB/Contract]
	WITH ENCRYPTION=OFF; 

	--Send the Message
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//WWI/SB/RequestMessage]
	(@RequestMessage);
	--SELECT @RequestMessage AS SentRequestMessage;--we can write data to log
	COMMIT TRAN 
END
GO


-- EXEC Sales.SendNewInvoice2 803,'20130101','20130129'

/*
SELECT	Start_request
									,	CustomerID
									,	DATE_BETWEEN
									,	QNTY
									,	MIND
									,	MAXD
							  FROM [Sales].[prc_Customers_reriod_New](803,'20130101','20130129')
							  FOR XML PATH('prc'), root('RequestMessage')


--

			Sales.SendNewInvoice2
*/
