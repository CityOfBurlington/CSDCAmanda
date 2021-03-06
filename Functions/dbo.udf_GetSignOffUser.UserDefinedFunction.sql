USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetSignOffUser]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetSignOffUser](@FolderRSN INT) RETURNS VARCHAR(400)
AS
BEGIN
	DECLARE @RetVal VARCHAR(400)
	
	SELECT @RetVal = ISNULL(FolderProcess.SignOffUser, '')
	FROM FolderProcess
	INNER JOIN ValidProcess ON FolderProcess.ProcessCode = ValidProcess.ProcessCode
	WHERE FolderRSN = @FolderRSN
	AND ValidProcess.ProcessDesc LIKE 'Final%'

	RETURN @RetVal
END
GO
