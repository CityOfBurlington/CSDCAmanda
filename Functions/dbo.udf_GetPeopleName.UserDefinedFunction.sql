USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPeopleName]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[udf_GetPeopleName](@intPeopleRSN INT) RETURNS VARCHAR(200)
AS 
BEGIN
	DECLARE @varRetVal VARCHAR(200)

	SELECT @varRetVal = RTRIM(LTRIM(ISNULL(People.NameFirst, '') + ' ' + ISNULL(People.NameLast, '')))
	FROM People
	WHERE PeopleRSN = @intPeopleRSN

	RETURN @varRetVal
END


GO
