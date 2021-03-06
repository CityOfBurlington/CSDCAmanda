USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetLastLRFolderDeedTransfer]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetLastLRFolderDeedTransfer](@PropertyRSN INT) RETURNS DATETIME
AS
BEGIN
	DECLARE @RetVal DATETIME

	SELECT @RetVal = MAX(dbo.f_info_date(Folder.FolderRSN, 2003))
	FROM Folder
	WHERE Folder.FolderType = 'LR'
	AND Folder.PropertyRSN = @PropertyRSN

	RETURN @RetVal
END
GO
