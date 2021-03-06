USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPeoplePhone1]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  FUNCTION [dbo].[udf_GetPeoplePhone1](@PeopleRSN int) 
	RETURNS VARCHAR(255)
AS
BEGIN
	DECLARE @varRetVal VARCHAR(255)

	SELECT TOP 1 @varRetVal = RTRIM(LTRIM(ISNULL(People.Phone1, '')))
	FROM People
	WHERE People.PeopleRSN = @PeopleRSN

	RETURN @varRetVal
END

GO
