USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderStatusCode]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetFolderStatusCode](@FolderRSN INT) RETURNS INT
AS 
BEGIN
	DECLARE @intStatusCode INT

	SELECT @intStatusCode = Folder.StatusCode
	  FROM Folder
	 WHERE Folder.FolderRSN = @FolderRSN
	
	RETURN ISNULL(@intStatusCode, 0)
END

GO
