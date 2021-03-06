USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProcessAttemptDateFYSpecific]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetProcessAttemptDateFYSpecific](@intFolderRSN INT, @intProcessCode INT, @intResultCode INT)
RETURNS VARCHAR(10)
AS
BEGIN
   DECLARE @dateAttemptDate datetime
   DECLARE @intInDateYear int
   DECLARE @intInDateMonth int
   DECLARE @intYrDiff int
   DECLARE @intCenturyDiff int
   DECLARE @intFY int
   DECLARE @varFiscalYear varchar(10)

   SELECT @dateAttemptDate = FolderProcessAttempt.AttemptDate
     FROM Folder, FolderProcess, FolderProcessAttempt
    WHERE Folder.FolderRSN = FolderProcess.FolderRSN
      AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
      AND FolderProcess.ProcessCode = @intProcessCode
     AND Folder.FolderRSN = @intFolderRSN
     AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcess, FolderProcessAttempt
          WHERE FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
            AND FolderProcess.ProcessCode = @intProcessCode
            AND FolderProcessAttempt.ResultCode = @intResultCode
            AND FolderProcessAttempt.FolderRSN = @intFolderRSN )

   SELECT @intInDateYear  = ISNULL(DATEPART(yy, @dateAttemptDate), 0)  
   SELECT @intInDateMonth = ISNULL(DATEPART(mm, @dateAttemptDate), 0)

   IF @intInDateMonth > 6 SELECT @intYrDiff = 1
   ELSE SELECT @intYrDiff = 0

   IF @intInDateYear < 2000 SELECT @intCenturyDiff = 1900
   ELSE SELECT @intCenturyDiff = 2000

   SELECT @intFY = ((@intInDateYear - @intCenturyDiff) + @intYrDiff)

   IF @intFY = 100 SELECT @intFY = 0

   IF @intFY < 10
      SELECT @varFiscalYear = 'FY0' + CAST(@intFY AS VARCHAR(4))
   ELSE 
      SELECT @varFiscalYear = 'FY' + CAST(@intFY AS VARCHAR(4))

   RETURN @varFiscalYear
END


GO
