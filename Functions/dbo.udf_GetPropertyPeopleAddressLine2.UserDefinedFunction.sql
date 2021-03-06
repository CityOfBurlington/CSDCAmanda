USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyPeopleAddressLine2]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPropertyPeopleAddressLine2](@intPropertyRSN INT, @intPeopleCode INT) RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @varAddressLine  VARCHAR(50)
	DECLARE @varAddressLine2 VARCHAR(50)
	DECLARE @varAddressLine3 VARCHAR(50)

	SELECT TOP 1 @varAddressLine2 = People.AddressLine2, 
				 @varAddressLine3 = People.AddressLine3
	FROM People
	INNER JOIN PropertyPeople ON People.PeopleRSN = PropertyPeople.PeopleRSN
	WHERE PropertyPeople.PropertyRSN = @intPropertyRSN
	AND PropertyPeople.PeopleCode = @intPeopleCode
	ORDER BY PropertyPeople.PeopleRSN
	
	IF LEN(@varAddressLine2) = 0 SELECT @varAddressLine = @varAddressLine3
	ELSE SELECT @varAddressLine = @varAddressLine2 
	
	RETURN ISNULL(@varAddressLine, '')
END

GO
