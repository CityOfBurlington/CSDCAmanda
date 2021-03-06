USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderStatus]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderStatus](@PropertyRSN INT, @FolderType CHAR(4), @StatusCode INT) RETURNS INT
AS 
BEGIN
	DECLARE @intRetVal INT

	SELECT @intRetVal = StatusCode
	FROM Folder
	WHERE FolderType = @FolderType
	AND PropertyRSN = @PropertyRSN
	AND StatusCode = @StatusCode

	RETURN ISNULL(@intRetVal, 0)
END

GO
