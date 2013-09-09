USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProcessDeficiencies]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetProcessDeficiencies](@FolderRSN INT)
RETURNS INT
AS
BEGIN
	DECLARE @RetVal int

	SELECT @RetVal = COUNT (*) FROM FolderProcessDeficiency
	WHERE FolderRSN = @FolderRSN

	RETURN @RetVal
END


GO
