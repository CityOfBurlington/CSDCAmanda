USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyPeopleAddressLine3]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPropertyPeopleAddressLine3](@intPropertyRSN INT, @intPeopleCode INT) RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @varAddressLine  VARCHAR(50)

	SELECT TOP 1 @varAddressLine = People.AddressLine3
	FROM People
	INNER JOIN PropertyPeople ON People.PeopleRSN = PropertyPeople.PeopleRSN
	WHERE PropertyPeople.PropertyRSN = @intPropertyRSN
	AND PropertyPeople.PeopleCode = @intPeopleCode
	ORDER BY PropertyPeople.PeopleRSN
	
	RETURN ISNULL(@varAddressLine, '')
END

GO
