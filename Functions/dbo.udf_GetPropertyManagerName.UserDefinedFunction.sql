USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyManagerName]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetPropertyManagerName](@PropertyRSN INT) RETURNS VARCHAR(200)
AS
BEGIN
	DECLARE @RetVal VARCHAR(200)
	DECLARE @FirstName VARCHAR(40)
	DECLARE @LastName VARCHAR(40)
	DECLARE @OrganizationName VARCHAR(50)
	DECLARE @FullName VARCHAR(80)

	SELECT @FirstName = RTRIM(LTRIM(ISNULL(People.NameFirst, ''))), 
		   @LastName = RTRIM(LTRIM(ISNULL(People.NameLast, ''))),
		   @OrganizationName = RTRIM(LTRIM(ISNULL(People.OrganizationName, '')))
	FROM PropertyPeople
	INNER JOIN People ON PropertyPeople.PeopleRSN = People.PeopleRSN
	WHERE PropertyPeople.PropertyRSN = @PropertyRSN
	AND PropertyPeople.PeopleCode = 75

	SET @FullName = @FirstName + ' ' + @LastName
	IF LEN(@FullName) > 1 SET @RetVal = @FullName ELSE SET @RetVal = @OrganizationName
	
	RETURN @RetVal	


END
GO
