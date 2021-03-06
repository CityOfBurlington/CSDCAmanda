USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyPeopleName]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPropertyPeopleName](@intPropertyRSN INT, @intPeopleCode INT) RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @varFullName VARCHAR(50)
	DECLARE @OrgName VARCHAR(50)

	SELECT TOP 1 @varFullName = RTRIM(LTRIM(ISNULL(People.NameFirst, '') + ' ' + ISNULL(People.NameLast, ''))),
		@OrgName = RTRIM(LTRIM(ISNULL(People.OrganizationName, '')))
	FROM People
	INNER JOIN PropertyPeople ON People.PeopleRSN = PropertyPeople.PeopleRSN
	WHERE PropertyPeople.PropertyRSN = @intPropertyRSN
	AND PropertyPeople.PeopleCode = @intPeopleCode
	ORDER BY People.PeopleRSN

	IF LEN(@varFullName) = 0 SET @varFullName = @OrgName
	
	RETURN ISNULL(@varFullName, '')
END
GO
