USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFiscalYearFromInDate]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFiscalYearFromInDate](@intFolderRSN INT) RETURNS VARCHAR(10)
AS
BEGIN
	DECLARE @intInDateYear int
	DECLARE @intInDateMonth int
	DECLARE @intYrDiff int
	DECLARE @intCenturyDiff int
        DECLARE @intFY int
	DECLARE @varRetVal varchar(10)

	SELECT @intInDateYear  = ISNULL(DATEPART(yy, Folder.InDate), 0), 
	       @intInDateMonth = ISNULL(DATEPART(mm, Folder.InDate), 0)
	  FROM Folder
	 WHERE Folder.FolderRSN = @intFolderRSN

	IF @intInDateMonth > 6 SELECT @intYrDiff = 1
	ELSE SELECT @intYrDiff = 0

	IF @intInDateYear < 2000 SELECT @intCenturyDiff = 1900
	ELSE SELECT @intCenturyDiff = 2000

        SELECT @intFY = ((@intInDateYear - @intCenturyDiff) + @intYrDiff)

	IF @intFY = 100 SELECT @intFY = 0

	IF @intFY < 10
	SELECT @varRetVal = 'FY0' + CAST(@intFY AS VARCHAR(4))

	ELSE 
	SELECT @varRetVal = 'FY' + CAST(@intFY AS VARCHAR(4))

	RETURN @varRetVal
END

GO
