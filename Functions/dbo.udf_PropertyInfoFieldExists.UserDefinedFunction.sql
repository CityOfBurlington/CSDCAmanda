USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_PropertyInfoFieldExists]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_PropertyInfoFieldExists](@intPropertyRSN int, @intInfoCode int) 
RETURNS INT
AS
BEGIN
   DECLARE @intFieldCount int

   SET @intFieldCount = 0   /* Info field does not exist */

   SELECT @intFieldCount = COUNT(*)
     FROM PropertyInfo
    WHERE PropertyInfo.PropertyRSN = @intPropertyRSN
      AND PropertyInfo.PropertyInfoCode = @intInfoCode

   RETURN @intFieldCount
END


GO
