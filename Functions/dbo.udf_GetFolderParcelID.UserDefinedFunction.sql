USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderParcelID]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderParcelID](@FolderRSN INT) RETURNS VARCHAR(13)
AS
BEGIN
	DECLARE @ParcelID VARCHAR(13)

	SELECT @ParcelID = Property.PropertyRoll
	FROM Folder
	INNER JOIN Property ON Folder.PropertyRSN = Property.PropertyRSN
	WHERE Folder.FolderRSN = @FolderRSN

	RETURN @ParcelID
END

GO
