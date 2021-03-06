USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetMHPropertyFolderStatus]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetMHPropertyFolderStatus](@PropertyRSN INT, @Year VARCHAR(2)) RETURNS VARCHAR(200)
AS
BEGIN
	DECLARE @RetVal VARCHAR(200)

	SELECT @RetVal=VS.StatusDesc
	FROM Folder F
	INNER JOIN ValidStatus VS ON F.StatusCode=VS.StatusCode
	WHERE F.FolderType='MH'
	AND F.PropertyRSN=@PropertyRSN
	AND F.FolderYear=@Year

	RETURN ISNULL(@RetVal, '')
END
GO
