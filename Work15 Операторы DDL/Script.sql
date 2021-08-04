/*
	���������� ������� - �������� ������ OLAP �� �������� �� �������� �� ����������� � ����� ������������ ��� ��������� �� �����, ������ ���������
	, ����������� ������ ����� ���������������� :) ����� ��������� ����� (�������������� ���� - ����)
	-- ������� ������ � �������� ��������, �������� �� ��� �� ������
	-- ����������� ��� ������ ������������ � ��� (��������) ��� ��� (1�)
*/
-- �������� ��������

CREATE DATABASE [FOT]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = FOT, FILENAME = N'D:\HomeWork\Work15 ��������� DDL\FOT.mdf' , 
	SIZE = 8MB , 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 65536KB )
GO

-- �������� �����
CREATE SCHEMA FOTF ;

USE FOT


CREATE TABLE FOTF.T_SPR_RECL
(
		RECL_ID INT NOT NULL		-- �� ��������
	,	DESCRIPTION VARCHAR(255)	-- �����������
 CONSTRAINT PK_RECL_ID PRIMARY KEY CLUSTERED 
(
	RECL_ID ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'������� ���������� � ������� ������������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_RECL'
GO

--	������ �� ���������� ��� ��� ���� ���� ����������, ����������

CREATE UNIQUE INDEX ind_SP_RECL_DESCRIPTION ON FOTF.T_SPR_RECL (DESCRIPTION DESC);

-- �����������, �������� ������� 0

ALTER TABLE FOTF.T_SPR_RECL 
ADD CONSTRAINT CHEK_num CHECK (RECL_ID>0)

/*	���������� ������ ����	*/

CREATE TABLE FOTF.T_SPR_STAT
(
		STAT_ID1 INT NOT NULL	-- �� ������ 1 ������ ������
	,	STAT1 VARCHAR(255)		-- ����������� 1 ������ ������
	,	STAT_ID2 INT NOT NULL	-- �� ������ 2 ������ ������
	,	STAT2 VARCHAR(255)		-- ����������� 4 ������ ������
	,	STAT_ID3 INT NOT NULL	-- �� ������ 3 ������ ������
	,	STAT3 VARCHAR(255)		-- ����������� 3 ������ ������
	,	STAT_ID4 INT NOT NULL	-- �� ������ 4 ������ ������
	,	STAT4 VARCHAR(255)		-- ����������� 4 ������ ������
 CONSTRAINT PK_STAT_ID PRIMARY KEY CLUSTERED 
(
	STAT_ID1 ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'���������� ������ ���� �����������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_STAT'
GO
--	����� �� �� ��� ��������� �������, ���� ���� � ��� ����������, ��������� ���� ����� ����� �� ����������, �� ����� �����������

CREATE INDEX ind_STAT_ID1 ON FOTF.T_SPR_STAT (STAT_ID1);
CREATE INDEX ind_STAT_ID2 ON FOTF.T_SPR_STAT (STAT_ID2);
CREATE INDEX ind_STAT_ID3 ON FOTF.T_SPR_STAT (STAT_ID3);
CREATE INDEX ind_STAT_ID4 ON FOTF.T_SPR_STAT (STAT_ID4);
CREATE INDEX ind_DESCRIPTINO_1 ON FOTF.T_SPR_STAT (STAT1);
CREATE INDEX ind_DESCRIPTINO_2 ON FOTF.T_SPR_STAT (STAT2);
CREATE INDEX ind_DESCRIPTINO_3 ON FOTF.T_SPR_STAT (STAT3);
CREATE INDEX ind_DESCRIPTINO_4 ON FOTF.T_SPR_STAT (STAT4);

									-- �����������, ��������  ������ �� 1 �� 1�
ALTER TABLE FOTF.T_SPR_STAT
ADD CONSTRAINT CHEK_NUM_1K CHECK (STAT_ID1>1 AND STAT_ID1>1000)


										-------------------------------
										/*	���������� ����� �������� */
										-------------------------------
CREATE TABLE FOTF.T_SPR_COSTS
(
		COST_ITEM_ID INT NOT NULL	-- �� ���� �������
	,	VID VARCHAR(255)			-- �����������
	,	STAT_ID1	INT				-- �������������� ��� ������� � ������
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

EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'���������� ����� �������� � �������� � ������� ����' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_COSTS'
EXEC sys.sp_addextendedproperty @name=N'COST_ITEM_ID', @value=N'������������� ���� ��������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_COSTS'
EXEC sys.sp_addextendedproperty @name=N'FUNCK_ID', @value=N'�������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_COSTS'
EXEC sys.sp_addextendedproperty @name=N'STAT_ID1', @value=N'�������� � ���� ������� ������ ����' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_COSTS'
EXEC sys.sp_addextendedproperty @name=N'FUNC_ID', @value=N'�������� �� �������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_COSTS'
EXEC sys.sp_addextendedproperty @name=N'UseFOT', @value=N'������������ � ������ ���' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_COSTS'
EXEC sys.sp_addextendedproperty @name=N'STAT_ID1', @value=N'������������ � ������ ����' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_COSTS'

-- �����������, �������� ������� ������������� ������
ALTER TABLE FOTF.T_SPR_COSTS ADD CONSTRAINT CHEK_UseFOT CHECK (UseFOT IN (1,0));
ALTER TABLE FOTF.T_SPR_COSTS ADD CONSTRAINT CHEK_UseMSFO CHECK (UseMSFO IN (1,0));


											----------------------
											/*���������� �������*/
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

EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'���������� ����� �������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_FUNK'

--	������ �� ���������� ��� ��� ���� ���� ����������, ����������

CREATE UNIQUE INDEX ind_SP_T_SPR_FUNK ON FOTF.T_SPR_FUNK (DESCRIPTION DESC);

-- �����������, �������� ������� �������� ��������
ALTER TABLE FOTF.T_SPR_FUNK ADD CONSTRAINT CHEK_LEN_FUNCK CHECK (LEN([DESCRIPTION])>1);


/*	���������� ����� ���������� �� ������� */

ALTER TABLE FOTF.T_SPR_COSTS
ADD CONSTRAINT FK_STAT_ID1 FOREIGN KEY (STAT_ID1)
REFERENCES FOTF.T_SPR_STAT (STAT_ID1)
;
/*	���������� ����� ���������� �� �������	*/
ALTER TABLE FOTF.T_SPR_COSTS
ADD CONSTRAINT FK_FUNC_ID FOREIGN KEY (FUNC_ID)
REFERENCES FOTF.T_SPR_FUNK (FUNC_ID)
;

									--------------------------------------
									/* ���������� ����������� ����������*/
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

EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'���������� ����������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_JOB_TITLE'

--	������ �� ���������� ��� ��� ���� ���� ����������, ����������
CREATE UNIQUE INDEX ind_SP_T_SPR_JOB_TITLE ON FOTF.T_SPR_JOB_TITLE (JOB DESC);

-- �����������, �������� ������� �������� ��������
ALTER TABLE FOTF.T_SPR_JOB_TITLE ADD CONSTRAINT CHEK_LEN_JOB_TITLE CHECK (LEN(JOB)>1);

										  -----------------------------------
										/* ���������� ����������� ������� */
										-----------------------------------

CREATE TABLE FOTF.T_SPR_MONTH
(
		MONTH_ID INT NOT NULL	--����� ������
	,	MONTH_NAME VARCHAR(35)	--�����
CONSTRAINT PK_MONTH_ID PRIMARY KEY CLUSTERED 
(
	MONTH_ID ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

CREATE INDEX ind_SPR_MONTH ON FOTF.T_SPR_MONTH (MONTH_NAME);

EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'���������� �������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_MONTH'

-- �����������, �������� ������� �������� �������� YYYYMM
ALTER TABLE FOTF.T_SPR_MONTH ADD CONSTRAINT CHEK_MONTH CHECK (MONTH_ID LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]');

										 -----------------------------------
										/*	���������� ������������� ���  */
										----------------------------------

CREATE TABLE FOTF.T_SPR_DIV_CFO
(
		CFO_ID INT NOT NULL	-- �� �������������
	,	OBJCT_ID INT NOT NULL -- �� �������
	,	GROUP_ID INT NOT NULL -- �� ������ �������
	,	GROUP_NAME VARCHAR(255) NOT NULL -- ������ ������� �����������
	,	LVL1_NAME VARCHAR(255) NOT NULL -- ������������� 1 ������
	,	LVL2_NAME VARCHAR(255) NOT NULL -- ������������� 2 ������
	,	LVL3_NAME VARCHAR(255) NOT NULL -- ������������� 3 ������
	,	LVL4_NAME VARCHAR(255) NOT NULL -- ������������� 4 ������
	,	LVL5_NAME VARCHAR(255) NOT NULL -- ������������� 5 ������
	,	CODE	VARCHAR(9)	NOT NULL	-- ��������� ���� ���
CONSTRAINT PK_CFO_ID PRIMARY KEY CLUSTERED 
(
	CFO_ID ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'���������� �������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_MONTH'


CREATE INDEX ind_OBJCT_ID ON FOTF.T_SPR_DIV_CFO (OBJCT_ID);
CREATE INDEX ind_GROUP_ID ON FOTF.T_SPR_DIV_CFO (GROUP_ID);
CREATE INDEX ind_CODE ON FOTF.T_SPR_DIV_CFO (CODE);

-- �����������, �������� ���� > 0
ALTER TABLE FOTF.T_SPR_DIV_CFO ADD CONSTRAINT CHEK_ID CHECK (CFO_ID > 0);


									 ---------------------------------	
									/*	���������� ������������� ���*/
									---------------------------------

CREATE TABLE FOTF.T_SPR_STAFF_DIV
(
		STAFF_DIV_ID INT NOT NULL	-- �� �������������
	,	ORG_NAME	VARCHAR(255) NOT NULL -- ������ ������� �����������
	,	LVL1_NAME	VARCHAR(255) NOT NULL -- ������������� 1 ������
	,	LVL2_NAME	VARCHAR(255) NOT NULL -- ������������� 2 ������
	,	LVL3_NAME	VARCHAR(255) NOT NULL -- ������������� 3 ������
	,	LVL4_NAME	VARCHAR(255) NOT NULL -- ������������� 4 ������
	,	LVL5_NAME	VARCHAR(255) NOT NULL -- ������������� 5 ������
	,	CODE		VARCHAR(9)	NOT NULL	-- ��������� ���� ��������� ���
CONSTRAINT PK_STAFF_DIV_ID PRIMARY KEY CLUSTERED 
(
	STAFF_DIV_ID ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

EXEC sys.sp_addextendedproperty @name=N'NAME', @value=N'���������� ������������� ���' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_STAFF_DIV'
EXEC sys.sp_addextendedproperty @name=N'ORG_NAME', @value=N'�����������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_STAFF_DIV'
EXEC sys.sp_addextendedproperty @name=N'LVL1_NAME', @value=N'�������������1 ������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_STAFF_DIV'
EXEC sys.sp_addextendedproperty @name=N'CODE', @value=N'��� ��� ������������ � �������� �����������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_STAFF_DIV'

--- ������, �� �� ��� ����� �� ������
CREATE INDEX ind_SPR_STAFF_DIV_CODE ON FOTF.T_SPR_STAFF_DIV (CODE);

-- �����������, �������� ���� > 0
ALTER TABLE FOTF.T_SPR_STAFF_DIV ADD CONSTRAINT CHEK_STAFF_ID CHECK (STAFF_DIV_ID > 0);


												 ---------------------------
												/*	���������� ���������� */
												---------------------------
CREATE TABLE FOTF.T_SPR_SOURCE
(
		IST_ID INT NOT NULL	-- �� ���������
	,	IST_NAME	VARCHAR(255) NOT NULL -- ����������� ���������
	,	GRP_ID		INT NOT NULL -- �� ������
	,	GRP_NAME	VARCHAR(255) NOT NULL -- ����������� ������
CONSTRAINT PK_IST_ID PRIMARY KEY CLUSTERED 
(
	IST_ID ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

EXEC sys.sp_addextendedproperty @name=N'NAME',		@value=N'���������� ����������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_SOURCE'
EXEC sys.sp_addextendedproperty @name=N'IST_ID',	@value=N'����� ���������'		, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_SOURCE'
EXEC sys.sp_addextendedproperty @name=N'IST_NAME',	@value=N'����������� ���������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_SOURCE'
EXEC sys.sp_addextendedproperty @name=N'GRP_ID',	@value=N'��� ������ ����������' , @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_SOURCE'
EXEC sys.sp_addextendedproperty @name=N'GRP_NAME',	@value=N'����������� ������'	, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SPR_SOURCE'

-- ������
CREATE UNIQUE INDEX ind_IST_NAME ON FOTF.T_SPR_SOURCE (IST_NAME DESC);

-- �����������, �������� ����� ������ 1 ������ 100
ALTER TABLE FOTF.T_SPR_SOURCE ADD CONSTRAINT CHEK_IST_ID CHECK (IST_ID >1 AND IST_ID<100);
-- ������������ �����
ALTER TABLE FOTF.T_SPR_SOURCE ADD CONSTRAINT CHEK_UNIQUE_NAME UNIQUE (IST_NAME);


												 ---------------------------
												/*	�������� ��� ������	 */
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
EXEC sys.sp_addextendedproperty @name=N'NAME',				@value=N'������������ ������� � �������'						, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'MONTH_ID',			@value=N'������'												, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'CFO_ID',			@value=N'������������� ������������� ���'						, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'CFO_ID2',			@value=N'�������� ������������� ��� ��������������'				, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'STAFF_DIV_ID',		@value=N'������������� ������������� ���'						, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'JOB_TITLE_ID',		@value=N'������������'											, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'JOB_TITLE_NAME',	@value=N'����������� ��������� (� ����� ����������� ����)'		, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'CAPITALIZ',			@value=N'������������� ����'									, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'ATTREBUTE_ID',		@value=N'������� ������ ������'									, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'IST',				@value=N'����� ���������'										, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'COST_ITEM_ID',		@value=N'���������������'										, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'SUMMA',				@value=N'�����������'											, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'
EXEC sys.sp_addextendedproperty @name=N'CAPEX',				@value=N'������������'											, @level0type=N'SCHEMA',@level0name=N'FOTF', @level1type=N'TABLE',@level1name=N'T_SOURCE_MAIN'

-- �������� ����, ��� �� ���� ������ 202101
ALTER TABLE FOTF.T_SPR_SOURCE ADD CONSTRAINT CHEK_MONTH CHECK (MONTH_ID>202101);

-- ������
CREATE INDEX ind_OBJCT_ID ON FOTF.T_SOURCE_MAIN (MONTH_ID);
CREATE INDEX ind_CFO_ID ON FOTF.T_SOURCE_MAIN (CFO_ID);
CREATE INDEX ind_CFO_ID2 ON FOTF.T_SOURCE_MAIN (CFO_ID2);
CREATE INDEX ind_STAFF_DIV_ID ON FOTF.T_SOURCE_MAIN (STAFF_DIV_ID);
CREATE INDEX ind_JOB_TITLE_ID ON FOTF.T_SOURCE_MAIN (JOB_TITLE_ID);
CREATE INDEX ind_ATTREBUTE_ID ON FOTF.T_SOURCE_MAIN (ATTREBUTE_ID);
CREATE INDEX ind_COST_ITEM_ID ON FOTF.T_SOURCE_MAIN (COST_ITEM_ID);

-- ����� ������
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
CREATE VIEW FOTF.V_SPR_CAPITALIZED
AS
SELECT CAST(0 AS INT) CAPITALIZ_ID	, CAST('�� �������������' AS VARCHAR(16)) AS DESCRIPTION
UNION ALL
SELECT CAST(1 AS INT)				, CAST('�������������' AS VARCHAR(16))
;
