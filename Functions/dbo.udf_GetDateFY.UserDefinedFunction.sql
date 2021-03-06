USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetDateFY]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetDateFY](@Date datetime) 
RETURNS INT
AS
BEGIN
   DECLARE @intFiscalYear INT
   SET @intFiscalYear = 0

   IF Month(@Date) >= 1 AND Month(@Date) <= 6 SET @intFiscalYear = YEAR(@Date) - 1
   IF Month(@Date) >= 7 AND Month(@Date) <= 12 SET @intFiscalYear = YEAR(@Date)
 
   RETURN @intFiscalYear
END

GO
