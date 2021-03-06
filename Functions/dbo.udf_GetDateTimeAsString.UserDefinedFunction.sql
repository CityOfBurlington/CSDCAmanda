USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetDateTimeAsString]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  FUNCTION [dbo].[udf_GetDateTimeAsString] (@varDate DATETIME) RETURNS VARCHAR(20)
AS 
BEGIN
	DECLARE @varRetVal VARCHAR(20)

SELECT @varRetVal = 
	STR(DATEPART(yyyy,@varDate), 4, 0) + 
	REPLACE(STR(DATEPART(m,@varDate), 2, 0), ' ', '0') +
	REPLACE(STR(DATEPART(d,@varDate), 2, 0), ' ', '0') + 
	REPLACE(STR(DATEPART(hour,@varDate), 2, 0), ' ', '0') +
	REPLACE(STR(DATEPART(minute,@varDate), 2, 0), ' ', '0') + 
	REPLACE(STR(DATEPART(s,@varDate), 2, 0), ' ', '0')
	--CAST(DATEPART(ms,@varDate) AS VARCHAR(3))

	RETURN @varRetVal
END

GO
