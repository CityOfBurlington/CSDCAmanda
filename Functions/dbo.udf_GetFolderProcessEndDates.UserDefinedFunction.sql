USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderProcessEndDates]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetFolderProcessEndDates](@intFolderRSN INT) RETURNS VARCHAR(4000)
AS
BEGIN
DECLARE @strComments	VARCHAR(4000)
DECLARE @strRetVal	VARCHAR(4000)
SET @strRetVal = ' '
DECLARE curAC CURSOR FOR
	SELECT ISNULL(CONVERT(VarChar(10), FolderProcess.EndDate, 101), '&nbsp;')
	FROM FolderProcess 
	INNER JOIN ValidProcess ON FolderProcess.ProcessCode = ValidProcess.ProcessCode
	INNER JOIN ValidProcessStatus ON FolderProcess.StatusCode = ValidProcessStatus.StatusCode
	WHERE FolderProcess.FolderRSN = @intFolderRSN
	ORDER BY FolderProcess.ProcessRSN

OPEN curAC
FETCH curAC INTO @strComments
WHILE @@FETCH_STATUS = 0
BEGIN	
	SET @strRetVal = @strRetVal + ' ' + @strComments + '<br>'
	FETCH curAC INTO @strComments
END
CLOSE curAC
DEALLOCATE curAC

RETURN @strRetVal
END

GO
