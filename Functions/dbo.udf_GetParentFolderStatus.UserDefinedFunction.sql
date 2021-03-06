USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetParentFolderStatus]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetParentFolderStatus](@ParentRSN AS INT) RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @RetVal VARCHAR(20)
	
	SELECT @RetVal = StatusDesc
	FROM Folder, ValidStatus
	WHERE FolderRSN = @ParentRSN AND Folder.StatusCode = ValidStatus.StatusCode
	
	RETURN @RetVal
END

GO
