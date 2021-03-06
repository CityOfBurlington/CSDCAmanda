USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFiscalYearQuarter]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetFiscalYearQuarter](@Date datetime) 
RETURNS VARCHAR(10)
AS
BEGIN
   DECLARE @intDateYear int
   DECLARE @intDateMonth int
   DECLARE @intYrDiff int
   DECLARE @intCenturyDiff int
   DECLARE @intFY int
   DECLARE @varFY varchar(10)
   DECLARE @intQuarter int
   DECLARE @varFYQuarter varchar(10)

   SELECT @intDateYear  = ISNULL(DATEPART(yy, @Date), 0), 
          @intDateMonth = ISNULL(DATEPART(mm, @Date), 0)

   IF @intDateMonth > 6 SELECT @intYrDiff = 1
   ELSE SELECT @intYrDiff = 0

   IF @intDateYear < 2000 SELECT @intCenturyDiff = 1900
   ELSE SELECT @intCenturyDiff = 2000

   SELECT @intFY = ((@intDateYear - @intCenturyDiff) + @intYrDiff)

   IF @intFY = 100 SELECT @intFY = 0

   IF @intFY < 10
      SELECT @varFY = 'FY0' + CAST(@intFY AS VARCHAR(4))

   ELSE 
   SELECT @varFY = 'FY' + CAST(@intFY AS VARCHAR(4))

   SELECT @intQuarter = 
   CASE 
      WHEN @intDateMonth IN (1, 2, 3) THEN 3
      WHEN @intDateMonth IN (4, 5, 6) THEN 4
      WHEN @intDateMonth IN (7, 8, 9) THEN 1
      WHEN @intDateMonth IN (10, 11, 12) THEN 2
      ELSE 0
   END

   SELECT @varFYQuarter = @varFY + '-' + CAST(@intQuarter AS VARCHAR(1))

   RETURN @varFYQuarter
END



GO
