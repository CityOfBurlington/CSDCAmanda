USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetIssueDateLong]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetIssueDateLong](@intFolderRSN INT) RETURNS VARCHAR(4000)
AS
BEGIN
DECLARE @strExpDate VARCHAR(4000)
SET @strExpDate = ' '
	SELECT @strExpDate = CONVERT(VarChar(11), Folder.IssueDate)
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

RETURN @strExpDate
END

GO
