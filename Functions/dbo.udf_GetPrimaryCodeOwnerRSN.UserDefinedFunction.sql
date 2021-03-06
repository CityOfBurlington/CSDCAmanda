USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPrimaryCodeOwnerRSN]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPrimaryCodeOwnerRSN](@PropertyRSN INT) RETURNS INT
AS
BEGIN
	DECLARE @RetVal INT

	SELECT TOP 1 @RetVal = PropertyPeople.PeopleRSN
	FROM PropertyPeople
	WHERE PropertyPeople.PropertyRSN = @PropertyRSN
	AND PropertyPeople.PeopleCode = 322
	ORDER BY PropertyPeople.PeopleRSN DESC

	RETURN @RetVal
END


GO
