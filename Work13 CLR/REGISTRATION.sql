CREATE ASSEMBLY CLR_HEX
FROM 'd:\CLR\CLR\CLR\bin\Debug\CLR.dll'
WITH PERMISSION_SET = SAFE;  
GO



SELECT * FROM sys.assemblies
GO

--	создаем CLR функцию
CREATE FUNCTION HEX_CHEK(@STR nvarchar(max), @pattern nvarchar(max))  
RETURNS BIT
AS EXTERNAL NAME CLR_HEX.Functions.IsMatch;  
GO 
-- проверка на наличие 
SELECT assembly_id, assembly_class, assembly_method
from sys.assembly_modules

-- Запуск пользовательских сборок
EXEC sp_configure 'clr enabled';  
EXEC sp_configure 'clr enabled' , '1';  
RECONFIGURE;    

DECLARE @PATTERN nvarchar(MAX) = '([\w-\.]+)@((?:[\w]+\.)+)([a-zA-Z]{2,4})'
	,	@NAME1 NVARCHAR(MAX)
	,	@NAME2 NVARCHAR(MAX)

SET @NAME1 = 'sychev_an@magnitru'
SET	@NAME2 = 'sychev_an@magnit.ru'



SELECT @NAME1 MAIL
	,  CASE 
			WHEN dbo.HEX_CHEK(@NAME1,@PATTERN) = 0
			THEN 'BAD '
			WHEN dbo.HEX_CHEK(@NAME1,@PATTERN) = 1
			THEN 'GOOD'
		END result
UNION ALL
SELECT @NAME2 
	,  CASE 
			WHEN dbo.HEX_CHEK(@NAME2,@PATTERN) = 0
			THEN 'BAD '
			WHEN dbo.HEX_CHEK(@NAME2,@PATTERN) = 1
			THEN 'GOOD'
		END
/*
MAIL	result
sychev_an@magnitru	BAD 
sychev_an@magnit.ru	GOOD
*/