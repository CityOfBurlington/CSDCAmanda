USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetLastPropertyFolderAttemptResult]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetLastPropertyFolderAttemptResult](@PropertyRSN INT, @FolderType CHAR(2)) RETURNS DATETIME
AS
BEGIN
	DECLARE @RetVal DATETIME

	SELECT @RetVal = MAX(FolderProcessAttempt.AttemptDate)
	FROM Folder
	INNER JOIN FolderProcessAttempt ON Folder.FolderRSN = FolderProcessAttempt.FolderRSN
	WHERE Folder.FolderType = @FolderType
	AND Folder.PropertyRSN = @PropertyRSN

	RETURN @RetVal	
END

GO
