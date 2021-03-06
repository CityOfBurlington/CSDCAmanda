USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyRentalUnits]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[udf_GetPropertyRentalUnits] (@arg_PropertyRSN INT)
RETURNS INT

AS
BEGIN

DECLARE	@RentalUnits INT

SELECT @RentalUnits = PropertyInfoValueNumeric
  FROM PropertyInfo
 WHERE PropertyRSN = @arg_PropertyRSN AND PropertyInfoCode = 20

RETURN @RentalUnits

END


GO
