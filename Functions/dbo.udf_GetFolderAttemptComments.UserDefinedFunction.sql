USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderAttemptComments]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderAttemptComments](@intFolderRSN INT) RETURNS VARCHAR(4000)
AS
BEGIN
DECLARE @strComments	VARCHAR(4000)
DECLARE @strRetVal	VARCHAR(4000)
SET @strRetVal = ' '
DECLARE curAC CURSOR FOR
	SELECT ISNULL(AttemptComment, ' ')
	FROM FolderProcessAttempt 
	WHERE FolderRSN = @intFolderRSN

OPEN curAC
FETCH curAC INTO @strComments
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @strRetVal = @strRetVal + @strComments + ' '
	FETCH curAC INTO @strComments
END
CLOSE curAC
DEALLOCATE curAC

RETURN ISNULL(RTRIM(LTRIM(@strRetVal)), ' ')
END


GO
