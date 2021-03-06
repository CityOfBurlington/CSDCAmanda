USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_CharToLongDate]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  FUNCTION [dbo].[udf_CharToLongDate](@varDate VARCHAR(30)) RETURNS VARCHAR(30)
AS 
BEGIN
	DECLARE @varRetVal VARCHAR(30)
	DECLARE @dtmDate DATETIME
	DECLARE @intMonth INT

	SELECT @dtmDate = CAST(@varDate AS DATETIME)

	SELECT @varRetVal = DATENAME(m, @dtmDate) + ' ' + CAST(DATEPART(DAY, @dtmDate) AS VARCHAR(2)) + ', ' + CAST(DATEPART(Year, @dtmDate) AS VARCHAR(4))

	RETURN @varRetVal
END


GO
