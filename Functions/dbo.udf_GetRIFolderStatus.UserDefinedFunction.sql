USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetRIFolderStatus]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[udf_GetRIFolderStatus](@FolderType VARCHAR(4), @PropertyRSN INT) RETURNS VARCHAR(30)
AS
BEGIN
	DECLARE @RetVal VARCHAR(30)
	DECLARE @FolderRSN INT

	SELECT TOP 1 @FolderRSN = Folder.FolderRSN, @RetVal = ValidStatus.StatusDesc
	FROM Folder
	INNER JOIN ValidStatus ON Folder.StatusCode = ValidStatus.StatusCode
	WHERE Folder.FolderType = @FolderType
	AND Folder.PropertyRSN = @PropertyRSN
	ORDER BY Folder.FolderRSN DESC

	RETURN @RetVal
END
GO
