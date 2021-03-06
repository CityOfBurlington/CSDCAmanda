USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFiscalYearQuarterFromInDate]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetFiscalYearQuarterFromInDate](@intFolderRSN INT) RETURNS VARCHAR(10)
AS
BEGIN
   DECLARE @intInDateYear int
   DECLARE @intInDateMonth int
   DECLARE @intYrDiff int
   DECLARE @intCenturyDiff int
   DECLARE @intFY int
   DECLARE @varFY varchar(10)
   DECLARE @intQuarter int
   DECLARE @varRetVal varchar(10)

   SELECT @intInDateYear  = ISNULL(DATEPART(yy, Folder.InDate), 0), 
          @intInDateMonth = ISNULL(DATEPART(mm, Folder.InDate), 0)
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   IF @intInDateMonth > 6 SELECT @intYrDiff = 1
   ELSE SELECT @intYrDiff = 0

   IF @intInDateYear < 2000 SELECT @intCenturyDiff = 1900
   ELSE SELECT @intCenturyDiff = 2000

   SELECT @intFY = ((@intInDateYear - @intCenturyDiff) + @intYrDiff)

   IF @intFY = 100 SELECT @intFY = 0

   IF @intFY < 10
      SELECT @varFY = 'FY0' + CAST(@intFY AS VARCHAR(4))

   ELSE 
   SELECT @varFY = 'FY' + CAST(@intFY AS VARCHAR(4))

   SELECT @intQuarter = 
   CASE 
      WHEN @intInDateMonth IN (1, 2, 3) THEN 3
      WHEN @intInDateMonth IN (4, 5, 6) THEN 4
      WHEN @intInDateMonth IN (7, 8, 9) THEN 1
      WHEN @intInDateMonth IN (10, 11, 12) THEN 2
      ELSE 0
   END

   SELECT @varRetVal = @varFY + '-' + CAST(@intQuarter AS VARCHAR(1))

   RETURN @varRetVal
END



GO
