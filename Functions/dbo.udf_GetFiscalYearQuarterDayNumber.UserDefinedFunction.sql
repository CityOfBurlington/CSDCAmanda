USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFiscalYearQuarterDayNumber]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFiscalYearQuarterDayNumber] (@Date datetime)
RETURNS INT
AS
BEGIN
   /* Calculate the start datetime of the fiscal year quarter for @Date.  */

   DECLARE @varQStart varchar(1)
   DECLARE @dateIncrement datetime
   DECLARE @intNumberofDays int

   SELECT @varQStart = 'N', 
          @dateIncrement = DATEADD(DAY, 0, DATEDIFF(DAY, 0, @Date))      /* Sets time to zero */

   WHILE @varQStart = 'N'
   BEGIN   
      IF DATEPART(MONTH, @dateIncrement) IN (1, 4, 7, 10) AND DATEPART(DAY, @dateIncrement) = 1
         SELECT @varQStart = 'Y'
      ELSE SELECT @dateIncrement = DATEADD(DAY, -1, @dateIncrement)
   END

   SELECT @intNumberofDays = DATEDIFF(dd, @dateIncrement, @Date)

   RETURN @intNumberofDays 
END





GO
