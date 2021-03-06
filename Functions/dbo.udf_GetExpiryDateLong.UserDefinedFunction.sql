USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetExpiryDateLong]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetExpiryDateLong](@intFolderRSN INT) RETURNS VARCHAR(4000)
AS
BEGIN
DECLARE @strExpDate VARCHAR(4000)
SET @strExpDate = ' '
	SELECT @strExpDate = CONVERT(VarChar(11), Folder.ExpiryDate)
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

RETURN @strExpDate
END

GO
