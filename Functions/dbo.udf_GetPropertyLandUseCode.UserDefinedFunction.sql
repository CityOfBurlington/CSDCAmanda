USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyLandUseCode]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[udf_GetPropertyLandUseCode] (@arg_PropertyRSN INT)
RETURNS VARCHAR(10)

AS
BEGIN

DECLARE	@RentalUnits VARCHAR(10)

SELECT @RentalUnits = PropInfoValue
  FROM PropertyInfo
 WHERE PropertyRSN = @arg_PropertyRSN AND PropertyInfoCode = 10

RETURN @RentalUnits

END


GO
