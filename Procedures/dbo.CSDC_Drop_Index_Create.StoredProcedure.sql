USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[CSDC_Drop_Index_Create]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[CSDC_Drop_Index_Create] as

DECLARE cur_Tabs Cursor for
   Select name From SysObjects Where Type = 'U'
      and exists (select 1 from all_AMANDA_TableNames where name = tablename)
      Order by 1


DECLARE @IndexName varchar(127)
DECLARE @TabName   varchar(127)
DECLARE @Keys      Varchar(255)
DECLARE @SQLStmt   Varchar(255)
DECLARE @FStat     SmallInt
Create table #xx_index (indname varchar(127), inddesc varchar(210), indkeys varchar(2078))
Create table #Drop_Index (SqlStmt varchar(255))


BEGIN
   OPEN cur_Tabs
   FETCH cur_Tabs INTO @TabName
   Set @FStat = @@Fetch_Status
   WHILE @FStat = 0
   BEGIN

      insert into #xx_index exec sp_helpindex @TabName

      DECLARE cur_index cursor for
         Select indname from #xx_Index

      OPEN cur_Index
      FETCH cur_Index INTO @IndexName
      WHILE @@Fetch_Status = 0
      BEGIN
         Set @SQLStmt = ('Drop Index ' + @TabName + '.' + @IndexName)
         Insert INTO #Drop_Index values ( @SQLStmt)
         Insert INTO #Drop_Index values ( 'GO')
         FETCH cur_Index INTO @IndexName
      END
      CLOSE cur_Index
      DEALLOCATE cur_Index
		Truncate table #xx_Index
      FETCH cur_Tabs INTO @TabName
      Set @FStat = @@Fetch_Status
   END
   CLOSE cur_Tabs
   DEALLOCATE cur_TABS

   Select * from #Drop_Index
END


GO
