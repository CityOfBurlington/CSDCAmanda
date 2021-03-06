USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetMHPropertyFolderSubDesc]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[udf_GetMHPropertyFolderSubDesc](@PropertyRSN INT, @Year VARCHAR(2)) RETURNS VARCHAR(200)
AS
BEGIN
	DECLARE @RetVal VARCHAR(200)

	SELECT @RetVal=VS.SubDesc
	FROM Folder F
	INNER JOIN ValidSub VS ON F.SubCode=VS.SubCode
	WHERE F.FolderType='MH'
	AND F.PropertyRSN=@PropertyRSN
	AND F.FolderYear=@Year

	RETURN ISNULL(@RetVal, '')
END

GO
