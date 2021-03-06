USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_DateToLongDate]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  FUNCTION [dbo].[udf_DateToLongDate](@varDate DATETIME) RETURNS VARCHAR(30)
AS 
BEGIN
	DECLARE @varRetVal VARCHAR(30)
	DECLARE @dtmDate DATETIME
	DECLARE @intMonth INT

	SET @dtmDate = @varDate

	SELECT @varRetVal = DATENAME(m, @dtmDate) + ' ' + CAST(DATEPART(DAY, @dtmDate) AS VARCHAR(2)) + ', ' + CAST(DATEPART(Year, @dtmDate) AS VARCHAR(4))

	RETURN @varRetVal
END

GO
