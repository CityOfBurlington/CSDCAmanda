USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFiscalYearQuarterStartDate]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFiscalYearQuarterStartDate] (@Date datetime)
RETURNS DATETIME
AS
BEGIN
   /* Calculates the start datetime of the current fiscal year quarter.  */

   DECLARE @varQStart varchar(1)
   DECLARE @dateIncrement datetime

   SELECT @varQStart = 'N', 
          @dateIncrement = DATEADD(DAY, 0, DATEDIFF(DAY, 0, @Date))      /* Sets time to zero */

   WHILE @varQStart = 'N'
   BEGIN   
      IF DATEPART(MONTH, @dateIncrement) IN (1, 4, 7, 10) AND DATEPART(DAY, @dateIncrement) = 1
         SELECT @varQStart = 'Y'
      ELSE SELECT @dateIncrement = DATEADD(DAY, -1, @dateIncrement)
   END

   RETURN @dateIncrement 
END


GO
