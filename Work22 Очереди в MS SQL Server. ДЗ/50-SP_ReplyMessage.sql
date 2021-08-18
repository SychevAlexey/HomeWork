drop procedure if exists Sales.GetNewInvoice2;
GO
CREATE OR ALTER PROCEDURE Sales.GetNewInvoice2
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER, --������������� �������
			@Message NVARCHAR(4000),--���������� ���������
			@MessageType Sysname,--��� ����������� ���������
			@ReplyMessage NVARCHAR(4000),--�������� ���������
			@InvoiceID INT,
			@xml XML; 
	
	BEGIN TRAN; 

	--Receive message from Initiator
	--����� �������� � �� �� 1 ���������
	--1 ������������ �� MS
	RECEIVE TOP(1)
		@TargetDlgHandle = Conversation_Handle,
		@Message = Message_Body,
		@MessageType = Message_Type_Name
	FROM dbo.TargetQueueWWI; 
-- SELECT * FROM dbo.TargetQueueWWI; 
	SELECT @Message; --������� � ������� ���������� �������
	--	COMMIT TRAN;

	SET @xml = CAST(@Message AS XML); -- �������� xml �� ��������
--COMMIT TRAN;
	--�������� InvoiceID �� xml
--	SELECT @InvoiceID = R.Iv.value('@InvoiceID','INT')
--	FROM @xml.nodes('/RequestMessage/Inv') as R(Iv);
-- 
INSERT INTO [Sales].LOG_SEND
SELECT 
			Start_request = R.[prc].value('Start_request[1]','DATETIME')
		,	CustomerID = R.prc.value('CustomerID[1]','INT')
		,	DATE_BETWEEN = R.[prc].value('DATE_BETWEEN[1]','varchar(80)')
		,	QNTY = R.[prc].value('QNTY[1]','INT')
		,	MIND = R.[prc].value('MIND[1]','DATE')
		,	MAXD = R.[prc].value('MAXD[1]','DATE')
 FROM @xml.nodes('RequestMessage/prc') as R(prc);

 --SELECT * FROM [Sales].LOG_SEND
	--��������� ���� � ������ ���� ��� InvoiceID
	--IF EXISTS (SELECT * FROM Sales.Invoices WHERE InvoiceID = @InvoiceID)
	--BEGIN
	--	UPDATE Sales.Invoices
	--	SET InvoiceConfirmedForProcessing = GETUTCDATE()
	--	WHERE InvoiceId = @InvoiceID;
	--END;
	
	SELECT @Message AS ReceivedRequestMessage, @MessageType; --� ���. ��������� ������
	
	-- Confirm and Send a reply
	IF @MessageType=N'//WWI/SB/RequestMessage'
	BEGIN
		SET @ReplyMessage =N'<ReplyMessage> Message received </ReplyMessage>'; 
	
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[//WWI/SB/ReplyMessage]
		(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle;--������� ������ �� ������� �������
	END 
	
	SELECT @ReplyMessage AS SentReplyMessage; --� ���

	COMMIT TRAN;
END



--EXEC Sales.GetNewInvoice2


--SELECT * FROM [Sales].LOG_SEND