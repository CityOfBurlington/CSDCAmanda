USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetIssueDateVeryLong]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_GetIssueDateVeryLong](@intFolderRSN INT) RETURNS VARCHAR(30)
AS
BEGIN
DECLARE @strLongDate VARCHAR(30)
SET @strLongDate = ' '
	SELECT @strLongDate = RTRIM(DATENAME(MONTH, Folder.IssueDate) + ' ' + DATENAME(DAY, Folder.IssueDate) + ', ' + DATENAME(YEAR, Folder.IssueDate))
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

RETURN @strLongDate
END



GO
