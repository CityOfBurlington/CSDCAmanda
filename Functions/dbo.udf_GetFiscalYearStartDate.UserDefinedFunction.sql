USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFiscalYearStartDate]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetFiscalYearStartDate] (@Date datetime)
RETURNS DATETIME
AS
BEGIN
   /* Calculates the start datetime of the fiscal year for @Date - JA 7/09 */

   DECLARE @FYStartDate datetime

   /* Set @FYStartDate to beginning of calendar year for @Date */ 

   SELECT @FYStartDate = DATEADD(YEAR, DATEDIFF(YEAR, 0, @Date), 0)

   IF DATEPART(MONTH, @Date) < 7 
      SELECT @FYStartDate = DATEADD(MONTH, -6, @FYStartDate)
   ELSE 
      SELECT @FYStartDate = DATEADD(MONTH,  6, @FYStartDate)

   RETURN @FYStartDate 
END

GO
