USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyPeopleNameFull]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPropertyPeopleNameFull](@intPropertyRSN INT, @intPeopleCode INT) 
RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE @varFirstName varchar(50)
	DECLARE @varLastName varchar(50)
	DECLARE @varOrganizationName varchar(100)
	DECLARE @varPeopleFullName varchar(100)

	SELECT TOP 1 @varFirstName = People.NameFirst, 
				 @varLastName = People.NameLast,
				 @varOrganizationName = People.OrganizationName
	FROM People
	INNER JOIN PropertyPeople ON People.PeopleRSN = PropertyPeople.PeopleRSN
	WHERE PropertyPeople.PropertyRSN = @intPropertyRSN
	AND PropertyPeople.PeopleCode = @intPeopleCode
	
	IF @varFirstName IS NOT NULL OR @varLastName IS NOT NULL
		SELECT @varPeopleFullName = LTRIM(RTRIM(@varFirstName + ' ' + @varLastName))

	IF @varOrganizationName IS NOT NULL SELECT @varPeopleFullName = @varOrganizationName
	
	RETURN ISNULL(@varPeopleFullName, '')
END

GO
