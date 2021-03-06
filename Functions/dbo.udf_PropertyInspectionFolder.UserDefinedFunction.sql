USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_PropertyInspectionFolder]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_PropertyInspectionFolder](@PropertyRSN INT) RETURNS INT
AS
BEGIN
	DECLARE @intRetVal INT

	SELECT @intRetVal = MAX(FolderRSN)
	FROM Folder
	WHERE FolderType IN('RI', 'QI')
	AND PropertyRSN = @PropertyRSN

	RETURN ISNULL(@intRetVal, 0)
END

GO
