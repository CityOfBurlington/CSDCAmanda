USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyPeopleRSN]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPropertyPeopleRSN](@intPropertyRSN INT, @intPeopleCode INT) RETURNS INT
AS
BEGIN
	DECLARE @PeopleRSN INT

	SELECT TOP 1 @PeopleRSN = PeopleRSN
	FROM PropertyPeople
	WHERE PropertyPeople.PropertyRSN = @intPropertyRSN
	AND PropertyPeople.PeopleCode = @intPeopleCode
	ORDER BY PeopleRSN
	
	--RETURN ISNULL(@PeopleRSN, 0)
	RETURN @PeopleRSN
END


GO
