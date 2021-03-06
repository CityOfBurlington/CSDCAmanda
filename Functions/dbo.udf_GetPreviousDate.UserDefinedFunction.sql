USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPreviousDate]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPreviousDate](
		@dtmTodaysDate datetime, 
		@intDaysToGoBack int, 
		@intDayOfMonthToReturn int) 
RETURNS DATETIME
AS
BEGIN

	DECLARE @dtmMonth VARCHAR(2)
	DECLARE @dtmDay   VARCHAR(2)
	DECLARE @dtmYear  VARCHAR(4)
	DECLARE @dtmMDY   DATETIME

	SET @dtmMonth	= CAST(MONTH(@dtmTodaysDate - @intDaysToGoBack) AS VARCHAR(2))
	SET @dtmDay	= CAST(@intDayOfMonthToReturn AS VARCHAR(2))
	SET @dtmYear	= CAST(YEAR(@dtmTodaysDate - @intDaysToGoBack) AS VARCHAR(4))
	SET @dtmMDY	= RTRIM(LTRIM(@dtmMonth)) + '/' + RTRIM(LTRIM(@dtmDay)) + '/' + RTRIM(LTRIM(@dtmYear))

	RETURN CAST(@dtmMDY AS DATETIME)
END

GO
