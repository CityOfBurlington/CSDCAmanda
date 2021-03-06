USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPrimaryCodeOwnerName]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPrimaryCodeOwnerName](@PropertyRSN INT) RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE @RetVal VARCHAR(100)

	SELECT TOP 1 @RetVal = People.NameFirst + ' ' + People.NameLast
	FROM PropertyPeople
	JOIN People ON PropertyPeople.PeopleRSN = People.PeopleRSN
	WHERE PropertyPeople.PropertyRSN = @PropertyRSN
	AND PropertyPeople.PeopleCode = 322
	ORDER BY PropertyPeople.PeopleRSN DESC

	RETURN @RetVal
END


GO
