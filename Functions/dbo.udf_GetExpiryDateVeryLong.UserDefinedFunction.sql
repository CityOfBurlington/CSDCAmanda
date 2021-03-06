USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetExpiryDateVeryLong]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetExpiryDateVeryLong](@intFolderRSN INT) RETURNS VARCHAR(30)
AS
BEGIN
DECLARE @strLongDate VARCHAR(30)
SET @strLongDate = ' '
	SELECT @strLongDate = RTRIM(DATENAME(MONTH, Folder.ExpiryDate) + ' ' + DATENAME(DAY, Folder.ExpiryDate) + ', ' + DATENAME(YEAR, Folder.ExpiryDate))
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

RETURN @strLongDate
END

GO
