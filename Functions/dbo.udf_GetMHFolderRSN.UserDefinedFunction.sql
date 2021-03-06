USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetMHFolderRSN]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetMHFolderRSN](@PropertyRSN INT) RETURNS INT 
AS
BEGIN
	DECLARE @intRetVal AS INT

	SELECT TOP 1 @intRetVal = FolderRSN
	FROM Folder
	WHERE FolderType = 'MH' AND StatusCode = 2 AND PropertyRSN = @PropertyRSN
	ORDER BY FolderRSN DESC

	RETURN @intRetVal
END


GO
