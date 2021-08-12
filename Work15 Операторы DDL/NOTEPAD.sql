/*
	Предметная область - создание отчета OLAP по расходам на персонал по организации в целях безопасности фио светиться не будет, только должность
	, отображение отчета будет кросплатформеным :) между системами учета (Управленческий Учет - МСФО)
	-- Входные данные в основном экселики, выгрузки из ЗУП за период
	-- справочники для работы затягиваются с КХД (Терадата) или КИС (1С)
*/
-- Создадим базульку

CREATE DATABASE [FOT]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = FOT, FILENAME = N'D:\IMPORT\FOT.mdf' , 
	SIZE = 8MB , 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 65536KB )
GO

-- Создадим схему
CREATE SCHEMA FOTF ;

USE FOT;


CREATE TABLE FOTF.T_SPR_RECL
(
		RECL_ID INT NOT NULL		-- ИД рекласса
	,	DESCRIPTION VARCHAR(255)	-- Расшифровка
 CONSTRAINT PK_RECL_ID PRIMARY KEY CLUSTERED 
(
	RECL_ID ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'Ресласс должностей в разрезе деятельности' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_RECL'
GO

--	Индекс не кластерный так как есть один кластерный, уникальный

CREATE UNIQUE INDEX ind_SP_RECL_DESCRIPTION ON FOTF.T_SPR_RECL (DESCRIPTION DESC);

-- Ограничение, значение большше 0

ALTER TABLE FOTF.T_SPR_RECL 
ADD CONSTRAINT CHEK_num CHECK (RECL_ID>0)

/*	Справочник статей МСФО	*/

CREATE TABLE FOTF.T_SPR_STAT
(
		STAT_ID1 INT NOT NULL	-- ИД статьи 1 уровня статьи
	,	STAT1 VARCHAR(255)		-- Расшифровка 1 уровня статьи
	,	STAT_ID2 INT NOT NULL	-- ИД статьи 2 уровня статьи
	,	STAT2 VARCHAR(255)		-- Расшифровка 4 уровня статьи
	,	STAT_ID3 INT NOT NULL	-- ИД статьи 3 уровня статьи
	,	STAT3 VARCHAR(255)		-- Расшифровка 3 уровня статьи
	,	STAT_ID4 INT NOT NULL	-- ИД статьи 4 уровня статьи
	,	STAT4 VARCHAR(255)		-- Расшифровка 4 уровня статьи
 CONSTRAINT PK_STAT_ID PRIMARY KEY CLUSTERED 
(
	STAT_ID1 ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'Справочник статей МСФО иерархичный' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_STAT'
GO
--	Здесь не на что создавать индексы, один есть и его достаточно, остальные поля особо нигде не учавствуют, но можно заморочится

CREATE INDEX ind_STAT_ID1 ON FOTF.T_SPR_STAT (STAT_ID1);
CREATE INDEX ind_STAT_ID2 ON FOTF.T_SPR_STAT (STAT_ID2);
CREATE INDEX ind_STAT_ID3 ON FOTF.T_SPR_STAT (STAT_ID3);
CREATE INDEX ind_STAT_ID4 ON FOTF.T_SPR_STAT (STAT_ID4);
CREATE INDEX ind_DESCRIPTINO_1 ON FOTF.T_SPR_STAT (STAT1);
CREATE INDEX ind_DESCRIPTINO_2 ON FOTF.T_SPR_STAT (STAT2);
CREATE INDEX ind_DESCRIPTINO_3 ON FOTF.T_SPR_STAT (STAT3);
CREATE INDEX ind_DESCRIPTINO_4 ON FOTF.T_SPR_STAT (STAT4);

									-- Ограничение, значение  номеру от 1 до 1к
ALTER TABLE FOTF.T_SPR_STAT
ADD CONSTRAINT CHEK_NUM_1K CHECK (STAT_ID1>1 AND STAT_ID1>1000)


										-------------------------------
										/*	Справочник видов расчетов */
										-------------------------------
CREATE TABLE FOTF.T_SPR_COSTS
(
		COST_ITEM_ID INT NOT NULL	-- ИД Вида расчета
	,	VID VARCHAR(255)			-- Расшифровка
	,	STAT_ID1	INT				-- Принадлежность виа расчета к статье
	,	FUNC_ID		INT				-- 
	,	UseFOT		tinyint NOT NULL
	,	UseMSFO		tinyint NOT NULL
CONSTRAINT PK_COST_ITEM_ID PRIMARY KEY CLUSTERED 
(
	COST_ITEM_ID ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
;

CREATE INDEX ind_VID ON FOTF.T_SPR_COSTS (COST_ITEM_ID);
CREATE INDEX ind_VID_STAT_ID1 ON FOTF.T_SPR_COSTS (STAT_ID1);
CREATE INDEX ind_VID_FUNC_ID ON FOTF.T_SPR_COSTS (FUNC_ID);
CREATE INDEX ind_VID_UseFOT ON FOTF.T_SPR_COSTS (UseFOT);
CREATE INDEX ind_VID_UseMSFO ON FOTF.T_SPR_COSTS (UseMSFO);

EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'Справочник видов расчетов и линковка к статьям МСФО' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_COSTS'
EXEC sys.sp_addextendedproperty @name=N'COST_ITEM_ID', @value=N'Идентификатор вида расчетов' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_COSTS'
EXEC sys.sp_addextendedproperty @name=N'FUNCK_ID', @value=N'Функция' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_COSTS'
EXEC sys.sp_addextendedproperty @name=N'STAT_ID1', @value=N'Привязка к виду расчтта статьи МСФО' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_COSTS'
EXEC sys.sp_addextendedproperty @name=N'FUNC_ID', @value=N'Привязка по функции' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_COSTS'
EXEC sys.sp_addextendedproperty @name=N'UseFOT', @value=N'Использовать в отчете ФОТ' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_COSTS'
EXEC sys.sp_addextendedproperty @name=N'STAT_ID1', @value=N'Использовать в отчете МСФО' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_COSTS'

-- Ограничение, проверим наличие использования отчета
ALTER TABLE FOTF.T_SPR_COSTS ADD CONSTRAINT CHEK_UseFOT CHECK (UseFOT IN (1,0));
ALTER TABLE FOTF.T_SPR_COSTS ADD CONSTRAINT CHEK_UseMSFO CHECK (UseMSFO IN (1,0));


											----------------------
											/*Справочник функций*/
											---------------------
CREATE TABLE [FOTF].[T_SPR_FUNK](
	[FUNC_ID] [int] NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
 CONSTRAINT [PK_FUNC_ID] PRIMARY KEY CLUSTERED 
(
	[FUNC_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] 
GO

EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'Справочник видов Функций' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_FUNK'

--	Индекс не кластерный так как есть один кластерный, уникальный

CREATE UNIQUE INDEX ind_SP_T_SPR_FUNK ON FOTF.T_SPR_FUNK (DESCRIPTION DESC);

-- Ограничение, проверим наличие вводимых символов
ALTER TABLE FOTF.T_SPR_FUNK ADD CONSTRAINT CHEK_LEN_FUNCK CHECK (LEN([DESCRIPTION])>1);


/*	Добавление ключа вторичного по статьям */

ALTER TABLE FOTF.T_SPR_COSTS
ADD CONSTRAINT FK_STAT_ID1 FOREIGN KEY (STAT_ID1)
REFERENCES FOTF.T_SPR_STAT (STAT_ID1)
;
/*	Добавление ключа вторичного по функции	*/
ALTER TABLE FOTF.T_SPR_COSTS
ADD CONSTRAINT FK_FUNC_ID FOREIGN KEY (FUNC_ID)
REFERENCES FOTF.T_SPR_FUNK (FUNC_ID)
;

									--------------------------------------
									/* Добавление справочника должностей*/
									-------------------------------------

CREATE TABLE FOTF.T_SPR_JOB_TITLE
(
		JOB_TITLE_ID INT NOT NULL 
	,	JOB VARCHAR(255)
CONSTRAINT PK_JOB_TITLE_ID PRIMARY KEY CLUSTERED 
(
	JOB_TITLE_ID ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE FOTF.T_SPR_JOB_TITLE ADD RECL INT;


EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'Справочник Должностей' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_JOB_TITLE'

--	Индекс не кластерный так как есть один кластерный, уникальный
CREATE UNIQUE INDEX ind_SP_T_SPR_JOB_TITLE ON FOTF.T_SPR_JOB_TITLE (JOB DESC);

-- Ограничение, проверим наличие вводимых символов
ALTER TABLE FOTF.T_SPR_JOB_TITLE ADD CONSTRAINT CHEK_LEN_JOB_TITLE CHECK (LEN(JOB)>1);

										  -----------------------------------
										/* Добавление справочника Периода */
										-----------------------------------

CREATE TABLE FOTF.T_SPR_MONTH
(
		MONTH_ID INT NOT NULL	--Номер месяца
	,	MONTH_NAME VARCHAR(35)	--Месяц
CONSTRAINT PK_MONTH_ID PRIMARY KEY CLUSTERED 
(
	MONTH_ID ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

CREATE INDEX ind_SPR_MONTH ON FOTF.T_SPR_MONTH (MONTH_NAME);

EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'Справочник Периода' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_MONTH'

-- Ограничение, проверим наличие вводимых символов YYYYMM
ALTER TABLE FOTF.T_SPR_MONTH ADD CONSTRAINT CHEK_MONTH CHECK (MONTH_ID LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]');

										 -----------------------------------
										/*	Справочник подразделений ЦФО  */
										----------------------------------

CREATE TABLE FOTF.T_SPR_DIV_CFO
(
		CFO_ID INT NOT NULL	-- ИД подразделения
	,	OBJCT_ID INT NOT NULL -- ИД Объекта
	,	GROUP_ID INT NOT NULL -- ИД Группа Объекта
	,	GROUP_NAME VARCHAR(255) NOT NULL -- Группа Объекта Расшифровка
	,	LVL1_NAME VARCHAR(255) NOT NULL -- Подразделение 1 уровня
	,	LVL2_NAME VARCHAR(255) NOT NULL -- Подразделение 2 уровня
	,	LVL3_NAME VARCHAR(255) NOT NULL -- Подразделение 3 уровня
	,	LVL4_NAME VARCHAR(255) NOT NULL -- Подразделение 4 уровня
	,	LVL5_NAME VARCHAR(255) NOT NULL -- Подразделение 5 уровня
	,	CODE	VARCHAR(9)	NOT NULL	-- Текстовое поле КИС
CONSTRAINT PK_CFO_ID PRIMARY KEY CLUSTERED 
(
	CFO_ID ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'Справочник Периода' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_MONTH'


CREATE INDEX ind_OBJCT_ID ON FOTF.T_SPR_DIV_CFO (OBJCT_ID);
CREATE INDEX ind_GROUP_ID ON FOTF.T_SPR_DIV_CFO (GROUP_ID);
CREATE INDEX ind_CODE ON FOTF.T_SPR_DIV_CFO (CODE);

-- Ограничение, проверим Кода > 0
ALTER TABLE FOTF.T_SPR_DIV_CFO ADD CONSTRAINT CHEK_ID CHECK (CFO_ID > 0);


									 ---------------------------------	
									/*	Справочник подразделений ЗУП*/
									---------------------------------

CREATE TABLE FOTF.T_SPR_STAFF_DIV
(
		STAFF_DIV_ID INT NOT NULL	-- ИД подразделения
	,	ORG_NAME	VARCHAR(255) NOT NULL -- Группа Объекта Расшифровка
	,	LVL1_NAME	VARCHAR(255) NOT NULL -- Подразделение 1 уровня
	,	LVL2_NAME	VARCHAR(255) NOT NULL -- Подразделение 2 уровня
	,	LVL3_NAME	VARCHAR(255) NOT NULL -- Подразделение 3 уровня
	,	LVL4_NAME	VARCHAR(255) NOT NULL -- Подразделение 4 уровня
	,	LVL5_NAME	VARCHAR(255) NOT NULL -- Подразделение 5 уровня
	,	CODE		VARCHAR(9)	NOT NULL	-- Текстовое поле Кодировка ЗУП
CONSTRAINT PK_STAFF_DIV_ID PRIMARY KEY CLUSTERED 
(
	STAFF_DIV_ID ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'Справочник подразделений ЗУП' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_STAFF_DIV'
EXEC sys.sp_addextendedproperty @name=N'ORG_NAME', @value=N'Организация' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_STAFF_DIV'
EXEC sys.sp_addextendedproperty @name=N'LVL1_NAME', @value=N'Подразделение1 уровня' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_STAFF_DIV'
EXEC sys.sp_addextendedproperty @name=N'CODE', @value=N'Код зуп уникальность в пределах организации' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_STAFF_DIV'

--- Индекс, не на что особо их вязать
CREATE INDEX ind_SPR_STAFF_DIV_CODE ON FOTF.T_SPR_STAFF_DIV (CODE);

-- Ограничение, проверим Кода > 0
ALTER TABLE FOTF.T_SPR_STAFF_DIV ADD CONSTRAINT CHEK_STAFF_ID CHECK (STAFF_DIV_ID > 0);


												 ---------------------------
												/*	Справочник исчтоников */
												---------------------------
CREATE TABLE FOTF.T_SPR_SOURCE
(
		IST_ID INT NOT NULL	-- ИД исчтоника
	,	IST_NAME	VARCHAR(255) NOT NULL -- Расшифровка Источника
	,	GRP_ID		INT NOT NULL -- ИД Группы
	,	GRP_NAME	VARCHAR(255) NOT NULL -- Расшифровка группы
CONSTRAINT PK_IST_ID PRIMARY KEY CLUSTERED 
(
	IST_ID ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

EXEC sys.sp_addextendedproperty @name=N'NAME',		@value=N'Справочник Источников' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_SOURCE'
EXEC sys.sp_addextendedproperty @name=N'IST_ID',	@value=N'Номер источника'		, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_SOURCE'
EXEC sys.sp_addextendedproperty @name=N'IST_NAME',	@value=N'Расшифровка источника' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_SOURCE'
EXEC sys.sp_addextendedproperty @name=N'GRP_ID',	@value=N'Код группы источников' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_SOURCE'
EXEC sys.sp_addextendedproperty @name=N'GRP_NAME',	@value=N'Расшифровка группы'	, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_SOURCE'

-- Индекс
CREATE UNIQUE INDEX ind_IST_NAME ON FOTF.T_SPR_SOURCE (IST_NAME DESC);

-- Ограничение, проверим номер больше 1 меньше 100
ALTER TABLE FOTF.T_SPR_SOURCE ADD CONSTRAINT CHEK_IST_ID CHECK (IST_ID >1 AND IST_ID<100);
-- Уникальность имени
ALTER TABLE FOTF.T_SPR_SOURCE ADD CONSTRAINT CHEK_UNIQUE_NAME UNIQUE (IST_NAME);


												 ---------------------------
												/*	Табличка для кубика	 */
												--------------------------
CREATE TABLE FOTF.T_SOURCE_MAIN
(
		MONTH_ID INT NOT NULL
	,	CFO_ID INT NOT NULL
	,	CFO_ID2 INT NOT NULL
	,	STAFF_DIV_ID INT NOT NULL
	,	JOB_TITLE_ID INT NOT NULL
	,	JOB_TITLE_NAME VARCHAR(255) NULL
	,	CAPITALIZ SMALLINT NOT NULL 
	,	ATTREBUTE_ID	SMALLINT
	,	IST INT	NOT NULL
	,	COST_ITEM_ID INT NOT NULL
	,	SUMMA	FLOAT	NULL
	,	CAPEX	FLOAT	NULL
 )
 ;

 ALTER TABLE FOTF.T_SOURCE_MAIN ALTER COLUMN SUMMA NUMERIC(20,8)
 ALTER TABLE FOTF.T_SOURCE_MAIN ALTER COLUMN CAPEX NUMERIC(20,8)

EXEC sys.sp_addextendedproperty @name=N'NAME',				@value=N'Камулятивная таличка с суммами'						, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'MONTH_ID',			@value=N'Период'												, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'CFO_ID',			@value=N'Идентификатор Подразделения КИС'						, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'CFO_ID2',			@value=N'Дубликат Подразделения КИС корректируемый'				, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'STAFF_DIV_ID',		@value=N'Идентификатор подразделения ЗУП'						, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'JOB_TITLE_ID',		@value=N'КодДолжности'											, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'JOB_TITLE_NAME',	@value=N'Расшифровка должности (в целях целостности базы)'		, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'CAPITALIZ',			@value=N'Капитализация сумм'									, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'ATTREBUTE_ID',		@value=N'Атрибут канала продаж'									, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'IST',				@value=N'Номер исчтоника'										, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'COST_ITEM_ID',		@value=N'КодВидаРасчетов'										, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'SUMMA',				@value=N'СуммаОпекса'											, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'CAPEX',				@value=N'СуммаКапекса'											, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'



-- Индекс
CREATE INDEX ind_OBJCT_ID ON FOTF.T_SOURCE_MAIN (MONTH_ID);
CREATE INDEX ind_CFO_ID ON FOTF.T_SOURCE_MAIN (CFO_ID);
CREATE INDEX ind_CFO_ID2 ON FOTF.T_SOURCE_MAIN (CFO_ID2);
CREATE INDEX ind_STAFF_DIV_ID ON FOTF.T_SOURCE_MAIN (STAFF_DIV_ID);
CREATE INDEX ind_JOB_TITLE_ID ON FOTF.T_SOURCE_MAIN (JOB_TITLE_ID);
CREATE INDEX ind_ATTREBUTE_ID ON FOTF.T_SOURCE_MAIN (ATTREBUTE_ID);
CREATE INDEX ind_COST_ITEM_ID ON FOTF.T_SOURCE_MAIN (COST_ITEM_ID);

-- Связи ключей
ALTER TABLE FOTF.T_SOURCE_MAIN
ADD CONSTRAINT FK_MONTH_ID FOREIGN KEY (MONTH_ID)
REFERENCES FOTF.T_SPR_MONTH (MONTH_ID)
;

 ALTER TABLE FOTF.T_SOURCE_MAIN
ADD CONSTRAINT FK_CFO_ID FOREIGN KEY (CFO_ID)
REFERENCES FOTF.T_SPR_DIV_CFO (CFO_ID)
;

 ALTER TABLE FOTF.T_SOURCE_MAIN
ADD CONSTRAINT FK_CFO_ID2 FOREIGN KEY (CFO_ID2)
REFERENCES FOTF.T_SPR_DIV_CFO (CFO_ID)
;

ALTER TABLE FOTF.T_SOURCE_MAIN
ADD CONSTRAINT FK_STAFF_DIV_ID FOREIGN KEY (STAFF_DIV_ID)
REFERENCES FOTF.T_SPR_STAFF_DIV (STAFF_DIV_ID)
;

ALTER TABLE FOTF.T_SOURCE_MAIN
ADD CONSTRAINT FK_JOB_TITLE_ID FOREIGN KEY (JOB_TITLE_ID)
REFERENCES FOTF.T_SPR_JOB_TITLE (JOB_TITLE_ID)
;

ALTER TABLE FOTF.T_SOURCE_MAIN
ADD CONSTRAINT FK_IST_ID FOREIGN KEY (IST)
REFERENCES FOTF.T_SPR_SOURCE (IST_ID)
;

ALTER TABLE FOTF.T_SOURCE_MAIN
ADD CONSTRAINT FK_COST_ITEM_ID FOREIGN KEY (COST_ITEM_ID)
REFERENCES FOTF.T_SPR_COSTS (COST_ITEM_ID)
;

SELECT * FROM FOTF.T_SPR_COSTS 
----------------------------------------------------------------------------------------------
CREATE VIEW FOTF.V_DIM_CAPITALIZED
AS
SELECT CAST(0 AS INT) CAPITALIZ_ID	, CAST('Не капитализация' AS VARCHAR(16)) AS DESCRIPTION
UNION ALL
SELECT CAST(1 AS INT)				, CAST('Капитализация' AS VARCHAR(16))
;


---------------------------------------------------------------------------------------

  INSERT INTO [FOT].[FOTF].[T_SPR_SOURCE] VALUES
  (2,'ЗУП',1,'Основные начисления'),
  (3,'Бонусы',1,'Основные начисления'),
  (4,'Резерв на оплату отпусков',1,'Основные начисления'),
  (5,'Данные КИС',2,'Дополнительные начисления'),
  (6,'Данные Вурш',3,'Данные мативационных файлов'),
  (7,'Данные СВП',3,'Данные мативационных файлов');


  INSERT INTO [FOT].[FOTF].[T_SPR_JOB_TITLE] VALUES 
   (1,'Продавец')
  ,(2,'Директор Магазина')
  ,(3,'Товаровед')
  ,(4,'Разработчик')
  ,(5,'Аналитик')
  ,(6,'Начальник отдела')
  ,(7,'Директор департамента')
  ,(8,'Секретарь')
  ,(9,'Менеджер')
  ,(10,'Системотехник')
  ,(11,'Директор филиала')
  ,(12,'Данные КИС')
  ,(13,'Сторож')
  ,(14,'Уборщица');

  UPDATE [FOT].[FOTF].[T_SPR_JOB_TITLE] 
  SET RECL = 3
  ;

   UPDATE [FOT].[FOTF].[T_SPR_JOB_TITLE] 
  SET RECL = 1
  WHERE JOB_TITLE_ID = 14
  ;

  UPDATE [FOT].[FOTF].[T_SPR_JOB_TITLE] 
  SET RECL = 2
  WHERE JOB_TITLE_ID = 13
  ;

  INSERT INTO [FOT].[FOTF].[T_SPR_COSTS] VALUES
  (1,'Оклад по дням' ,1,0,1,1),
  (2,'Оклад по Часам',2,0,1,1),
  (3,'Страховые отчисления',4,0,1,1),
  (4,'Усиление СВП',2,0,1,1),
  (5,'Вурш',2,0,1,1),
  (6,'Квартальные бонусы',3,0,1,1),
  (7,'Полугодовые бонусы',3,0,1,0),
  (8,'Годовые бонусы',3,0,1,1),
  (9,'Отпускные',5,0,1,1),
  (10,'Больничные',6,0,1,1),
  (11,'Командировочные',7,0,1,1),
  (12,'Резерв на оплату отпуска',8,0,1,1);


  INSERT INTO [FOT].[FOTF].[T_SPR_STAT] VALUES
  (1,'Оплата труда-Постоянная часть'	,1,'Оплата труда-Постоянная часть'	,14,	'Расходы на регулярную оплату труда',13,'Расходы на персонал'),
  (2,'Оплата труда-Часовая часть'		,2,'Оплата труда-Часовая часть'		,14,	'Расходы на регулярную оплату труда',13,'Расходы на персонал'),
  (3,'Оплата труда-Премиальная часть'	,3,'Оплата труда-Премиальная часть'	,14,	'Расходы на регулярную оплату труда',13,'Расходы на персонал'),
  (4,'Налоги и взносы'					,4,'Налоги и взносы'				,4,		'Налоги и взносы'					,13,'Расходы на персонал'),
  (5,'Оплата труда-Отпусные'			,5,'Оплата труда-Отпусные'			,15,	'Расходы на отпуск'					,13,'Расходы на персонал'),
  (6,'Оплата труда-Больничные'			,6,'Оплата труда-Больничные'		,6,		'Оплата труда-Больничные'			,13,'Расходы на персонал'),
  (7,'Командировочные-проезд'			,7,'Командировочные-проезд'			,15,	'Командировочные расходы'			,16,'Прочие доходы/расходы'),
  (8,'Резерв на уплату отпусков'		,8,'Резерв на уплату отпусков'		,15,	'Расходы на отпуск'					,13,'Расходы на персонал');

  INSERT INTO [FOT].[FOTF].[T_SOURCE_MAIN]
  ([MONTH_ID]
      ,[CFO_ID]
      ,[CFO_ID2]
      ,[STAFF_DIV_ID]
      ,[JOB_TITLE_ID]
      ,[JOB_TITLE_NAME]
      ,[CAPITALIZ]
      ,[ATTREBUTE_ID]
      ,[IST]
      ,[COST_ITEM_ID]
      ,[SUMMA]
      ,[CAPEX])
  SELECT [MONTH_ID]
      ,[CFO_ID]
      ,[CFO_ID2]
      ,[STAFF_DIV_ID]
      ,[JOB_TITLE_ID]
      ,[JOB_TITLE_NAME]
      ,[CAPITALIZ]
      ,[ATTREBUTE_ID]
      ,[IST]
      ,[COST_ITEM_ID]
      ,[SUMMA]
      ,[CAPEX] FROM DBo.MASSIV


SELECT	IST.MONTH_ID
	,	CFO.GROUP_NAME
	,	DIV.ORG_NAME
	,	CFO.LVL5_NAME
	,	JOB.JOB
	,	COST.COST_ITEM_ID
	,	COST.VID
	FROM FOTF.T_SOURCE_MAIN IST
		JOIN [FOTF].[T_SPR_STAFF_DIV] DIV ON DIV.STAFF_DIV_ID = IST.STAFF_DIV_ID
			JOIN [FOTF].[T_SPR_DIV_CFO] CFO ON CFO.CFO_ID = IST.CFO_ID2
				JOIN [FOTF].[T_SPR_COSTS] COST ON COST.COST_ITEM_ID = IST.COST_ITEM_ID
					JOIN [FOTF].[T_SPR_JOB_TITLE] JOB ON JOB.JOB_TITLE_ID = IST.JOB_TITLE_ID
WHERE MONTH_ID = 202103





SELECT * FROM [FOTF].[T_SPR_JOB_TITLE]
WHERE JOB = 'Продавец' OR JOB_TITLE_ID = 3

--DROP INDEX [FOTF].[T_SPR_JOB_TITLE].[ind_SP_T_SPR_JOB_TITLE]


CREATE NONCLUSTERED INDEX IX_JOB_TITLE_ID_JOB
ON [FOTF].[T_SPR_JOB_TITLE]
(
	[JOB_TITLE_ID] ASC
)
INCLUDE(JOB)
GO


DROP INDEX IX_T_SPR_COSTS_VID
ON [FOTF].[T_SPR_COSTS]

CREATE NONCLUSTERED INDEX IX_JOB_TITLE_ID_JOB
ON [FOTF].[T_SPR_JOB_TITLE]
(
	[JOB_TITLE_ID] ASC
)
INCLUDE(JOB)
GO;

CREATE NONCLUSTERED INDEX IX_SPR_COST_VID_STAT1
ON [FOTF].[T_SPR_COSTS]
(
	COST_ITEM_ID ASC
)
INCLUDE(Vid,STAT_ID1)
GO

