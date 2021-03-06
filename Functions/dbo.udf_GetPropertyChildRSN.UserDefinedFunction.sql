USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyChildRSN]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPropertyChildRSN] (@intPropertyRSN INT)
RETURNS INT

AS
BEGIN
   DECLARE @intChildRSN int
   SET @intChildRSN = 0

   SELECT @intChildRSN = Property.PropertyRSN 
     FROM Property
    WHERE ( Property.PropertyRSN = @intPropertyRSN OR Property.ParentPropertyRSN = @intPropertyRSN ) 
      AND Property.StatusCode in (1, 3)


RETURN @intChildRSN

END

GO
