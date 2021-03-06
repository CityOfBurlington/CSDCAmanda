USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFiscalYear]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetFiscalYear](@Date datetime) 
RETURNS VARCHAR(10)
AS
BEGIN
	DECLARE @intIssueDateYear int
	DECLARE @intIssueDateMonth int
	DECLARE @intYrDiff int
	DECLARE @intCenturyDiff int
        DECLARE @intFY int
	DECLARE @varRetVal varchar(10)

	SELECT @intIssueDateYear  = ISNULL(DATEPART(yy, @Date), 0), 
	       @intIssueDateMonth = ISNULL(DATEPART(mm, @Date), 0)

	IF @intIssueDateMonth > 6 SELECT @intYrDiff = 1
	ELSE SELECT @intYrDiff = 0

	IF @intIssueDateYear < 2000 SELECT @intCenturyDiff = 1900
	ELSE SELECT @intCenturyDiff = 2000

        SELECT @intFY = ((@intIssueDateYear - @intCenturyDiff) + @intYrDiff)

	IF @intFY = 100 SELECT @intFY = 0

	IF @intFY < 10
	SELECT @varRetVal = 'FY0' + CAST(@intFY AS VARCHAR(4))

	ELSE 
	SELECT @varRetVal = 'FY' + CAST(@intFY AS VARCHAR(4))

	RETURN @varRetVal
END



GO
