USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyExemptUnits]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[udf_GetPropertyExemptUnits] (@arg_PropertyRSN INT)
RETURNS INT

AS
BEGIN

DECLARE	@RentalUnits INT

SELECT @RentalUnits = PropertyInfoValueNumeric
  FROM PropertyInfo
 WHERE PropertyRSN = @arg_PropertyRSN AND PropertyInfoCode = 23

RETURN @RentalUnits

END


GO
