USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFiscalYearFromLastAttemptResult]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFiscalYearFromLastAttemptResult](@intFolderRSN INT, @intProcessCode INT) RETURNS VARCHAR(10)
AS
BEGIN
	DECLARE @dateAttemptDate datetime
	DECLARE @intAttemptDateYear int
	DECLARE @intAttemptDateMonth int
	DECLARE @intYrDiff int
	DECLARE @intCenturyDiff int
        DECLARE @intFY int
	DECLARE @varRetVal varchar(10)

	SELECT TOP 1 @dateAttemptDate = FolderProcessAttempt.AttemptDate
	FROM FolderProcessAttempt, FolderProcess
	WHERE FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
	AND FolderProcess.ProcessCode = @intProcessCode
	AND FolderProcessAttempt.FolderRSN = @intFolderRSN
	ORDER BY FolderProcessAttempt.AttemptRSN DESC

	SELECT @intAttemptDateYear  = ISNULL(DATEPART(yy, @dateAttemptDate), 0), 
	       @intAttemptDateMonth = ISNULL(DATEPART(mm, @dateAttemptDate), 0)
	
	IF @intAttemptDateMonth > 6 SELECT @intYrDiff = 1
	ELSE SELECT @intYrDiff = 0

	IF @intAttemptDateYear < 2000 SELECT @intCenturyDiff = 1900
	ELSE SELECT @intCenturyDiff = 2000

        SELECT @intFY = ((@intAttemptDateYear - @intCenturyDiff) + @intYrDiff)

	IF @intFY = 100 SELECT @intFY = 0

	IF @intFY < 10
	SELECT @varRetVal = 'FY0' + CAST(@intFY AS VARCHAR(4))

	ELSE 
	SELECT @varRetVal = 'FY' + CAST(@intFY AS VARCHAR(4))

	RETURN @varRetVal
END

GO
