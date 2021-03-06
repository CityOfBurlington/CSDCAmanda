USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyAddressShort]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPropertyAddressShort](@intPropertyRSN INT) RETURNS VARCHAR(2000)
AS
BEGIN
	DECLARE @strShortAddress VARCHAR(2000)

	SELECT @strShortAddress = RTRIM(LTRIM(
	ISNULL(Property.PropHouse, '') + ' ' + 
	ISNULL(Property.PropStreetUpper, '') + ' ' + 
	ISNULL(Property.PropStreetType, '') + ' ' + 
	ISNULL(Property.PropUnitType, '') + ' ' + 
	ISNULL(Property.PropUnit, '')
	))
	FROM Property
	WHERE Property.PropertyRSN = @intPropertyRSN

	RETURN UPPER(ISNULL(@strShortAddress, ''))
END

GO
