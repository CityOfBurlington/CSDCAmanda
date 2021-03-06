USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_FindNullValueTables]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_FindNullValueTables](@ColumnName VARCHAR(100)) 
AS
BEGIN

DECLARE @TableName VARCHAR(100)
DECLARE @SQL NVARCHAR(400)
DECLARE @RC INT
SET @RC = 0

CREATE TABLE #temp (TableName VARCHAR(100), NullCount INT)

DECLARE curTables CURSOR FOR
	SELECT sysobjects.name AS TableName
	FROM syscolumns 
	INNER JOIN sysobjects ON syscolumns.id = sysobjects.id
	WHERE syscolumns.name = @ColumnName

OPEN curTables

FETCH NEXT FROM curTables INTO @TableName

WHILE @@FETCH_STATUS = 0 BEGIN
	SET @SQL = N'INSERT INTO #temp SELECT ''' + @TableName + ''', SUM(1) FROM ' + @TableName + ' WHERE ' + @ColumnName + ' IS NULL'
	EXEC @RC = sp_executesql @SQL
	SET @RC = 0
	FETCH NEXT FROM curTables INTO @TableName
END

CLOSE curTables
DEALLOCATE curTables

IF NOT EXISTS(SELECT * FROM #temp)
	BEGIN
		PRINT 'THERE ARE NO TABLES WITH NULL ''' + @ColumnName + ''''
	END
ELSE
	BEGIN
		SELECT * FROM #temp
	END

DROP TABLE #temp

END
GO
