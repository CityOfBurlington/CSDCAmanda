USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetParentFolderType]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetParentFolderType](@ParentRSN AS INT) RETURNS VARCHAR(4)
AS
BEGIN
	DECLARE @RetVal VARCHAR(4)
	
	SELECT @RetVal = FolderType
	FROM Folder
	WHERE FolderRSN = @ParentRSN
	
	RETURN @RetVal
END


GO
