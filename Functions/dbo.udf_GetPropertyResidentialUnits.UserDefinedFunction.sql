USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyResidentialUnits]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[udf_GetPropertyResidentialUnits] (@arg_PropertyRSN INT)
RETURNS INT

AS
BEGIN

DECLARE	@ResidentialUnits INT

SELECT @ResidentialUnits = PropInfoValue
  FROM PropertyInfo
 WHERE PropertyRSN = @arg_PropertyRSN AND PropertyInfoCode = 15

RETURN @ResidentialUnits

END


GO
