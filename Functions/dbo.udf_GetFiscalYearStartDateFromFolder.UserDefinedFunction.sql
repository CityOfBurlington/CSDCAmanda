USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFiscalYearStartDateFromFolder]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFiscalYearStartDateFromFolder](@pFolderRSN INT) RETURNS DATETIME
AS
BEGIN
	DECLARE @varFolderYear AS VARCHAR(2)
	DECLARE @varFolderDate AS VARCHAR(10)
	DECLARE @dtmRetVal AS DATETIME

	SELECT @varFolderYear = FolderYear 
	FROM Folder
	WHERE FolderRSN = @pFolderRSN

	SET @varFolderDate = '20' + @varFolderYear + '-07-01'

	SET @dtmRetVal = CAST(@varFolderDate AS DATETIME)

	SET @dtmRetVal = DATEADD(YEAR, -1, @dtmRetVal)

	RETURN @dtmRetVal
END


GO
