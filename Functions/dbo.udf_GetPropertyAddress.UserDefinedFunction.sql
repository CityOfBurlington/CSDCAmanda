USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyAddress]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPropertyAddress](@intPropertyRSN INT) RETURNS VARCHAR(2000)
AS
BEGIN
	DECLARE @strFullAddress VARCHAR(2000)

	SELECT @strFullAddress = RTRIM(LTRIM(
	ISNULL(Property.PropHouse, '') + ' ' + 
	ISNULL(Property.PropStreetUpper, '') + ' ' + 
	ISNULL(ValidStreetType.StreetTypeDesc, '') + ' ' + 
	ISNULL(Property.PropUnitType, '') + ' ' + 
	ISNULL(Property.PropUnit, '')
	))
	FROM Property
	LEFT OUTER JOIN ValidStreetType ON Property.PropStreetType = ValidStreetType.StreetType
	WHERE Property.PropertyRSN = @intPropertyRSN

	RETURN UPPER(ISNULL(@strFullAddress, ''))
END

GO
