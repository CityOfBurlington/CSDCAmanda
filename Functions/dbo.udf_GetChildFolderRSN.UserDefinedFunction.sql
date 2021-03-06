USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetChildFolderRSN]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetChildFolderRSN](@FolderRSN INT) RETURNS INT
AS
BEGIN
	DECLARE @RetVal INT

	SELECT TOP 1 @RetVal = FolderRSN
	FROM Folder
	WHERE ParentRSN = @FolderRSN

	RETURN @RetVal

END


GO
