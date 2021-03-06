USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetDateAsString]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  FUNCTION [dbo].[udf_GetDateAsString] (@varDate DATETIME) RETURNS VARCHAR(20)
AS 
BEGIN
	DECLARE @varRetVal VARCHAR(20)

	SELECT @varRetVal = CAST(DATEPART(yyyy,@varDate) AS CHAR(4)) + 
	CAST(DATEPART(m,@varDate) AS VARCHAR(2)) +
	CAST(DATEPART(d,@varDate)AS VARCHAR(2)) --+ 
--	CAST(DATEPART(hour,@varDate) AS VARCHAR(2)) +
--	CAST(DATEPART(minute,@varDate) AS VARCHAR(2)) + 
--	CAST(DATEPART(s,@varDate) AS VARCHAR(2)) +
--	CAST(DATEPART(ms,@varDate) AS VARCHAR(3))

	RETURN @varRetVal
END

GO
