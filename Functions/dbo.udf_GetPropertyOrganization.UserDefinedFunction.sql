USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyOrganization]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPropertyOrganization](@PropertyRSN INT, @PeopleCode INT) RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE @RetVal VARCHAR(100)

	SELECT @RetVal = People.OrganizationName
	FROM PropertyPeople
	INNER JOIN People ON PropertyPeople.PeopleRSN = People.PeopleRSN
	WHERE PropertyPeople.PropertyRSN = @PropertyRSN
	AND PropertyPeople.PeopleCode = @PeopleCode

	RETURN ISNULL(@RetVal, '')
END

GO
