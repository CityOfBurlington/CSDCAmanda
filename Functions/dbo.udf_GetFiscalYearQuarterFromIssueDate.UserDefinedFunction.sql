USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFiscalYearQuarterFromIssueDate]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_GetFiscalYearQuarterFromIssueDate](@intFolderRSN INT) RETURNS VARCHAR(10)
AS
BEGIN
   DECLARE @intIssueDateYear int
   DECLARE @intIssueDateMonth int
   DECLARE @intYrDiff int
   DECLARE @intCenturyDiff int
   DECLARE @intFY int
   DECLARE @varFY varchar(10)
   DECLARE @intQuarter int
   DECLARE @varRetVal varchar(10)

   SELECT @intIssueDateYear  = ISNULL(DATEPART(yy, Folder.IssueDate), 0), 
                  @intIssueDateMonth = ISNULL(DATEPART(mm, Folder.IssueDate), 0)
       FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   IF @intIssueDateMonth > 6 SELECT @intYrDiff = 1
   ELSE SELECT @intYrDiff = 0

   IF @intIssueDateYear < 2000 SELECT @intCenturyDiff = 1900
   ELSE SELECT @intCenturyDiff = 2000

   SELECT @intFY = ((@intIssueDateYear - @intCenturyDiff) + @intYrDiff)

   IF @intFY = 100 SELECT @intFY = 0

   IF @intFY < 10
      SELECT @varFY = 'FY0' + CAST(@intFY AS VARCHAR(4))

   ELSE 
   SELECT @varFY = 'FY' + CAST(@intFY AS VARCHAR(4))

   SELECT @intQuarter = 
   CASE 
      WHEN @intIssueDateMonth IN (1, 2, 3) THEN 3
      WHEN @intIssueDateMonth IN (4, 5, 6) THEN 4
      WHEN @intIssueDateMonth IN (7, 8, 9) THEN 1
      WHEN @intIssueDateMonth IN (10, 11, 12) THEN 2
      ELSE 0
   END

   SELECT @varRetVal = @varFY + '-' + CAST(@intQuarter AS VARCHAR(1))

   RETURN @varRetVal
END

GO
