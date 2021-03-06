USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyOwnerCount]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetPropertyOwnerCount](@intPropertyRSN INT)
RETURNS INT
AS
BEGIN
	DECLARE @intOwnerCount int
	SET @intOwnerCount = 0
	
	SELECT @intOwnerCount = COUNT(*)
	FROM Property, PropertyPeople
	WHERE Property.PropertyRSN = PropertyPeople.PropertyRSN
	AND PropertyPeople.PeopleCode = 2		/* Owner */
	AND Property.PropertyRSN = @intPropertyRSN

	RETURN @intOwnerCount
END

GO
