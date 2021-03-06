USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningPermitReferenceForm]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningPermitReferenceForm](@intFolderRSN INT)
RETURNS VARCHAR(40)
AS
BEGIN
/* Used for Infomaker form zoning_all_permits, e.g. See Conditions of Approval */
DECLARE @strSeeReference varchar(50)
DECLARE @intProcessCode int
DECLARE @intAttemptCode int

SET @strSeeReference = 'x'
SET @intAttemptCode = 0 

SELECT @intProcessCode = dbo.udf_GetZoningDecisionProcessCode(@intFolderRSN)

SELECT @intAttemptCode = FolderProcessAttempt.ResultCode
FROM Folder, FolderProcess, FolderProcessAttempt 
WHERE Folder.FolderRSN = FolderProcess.FolderRSN
AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
AND FolderProcess.ProcessCode = @intProcessCode
AND Folder.FolderRSN = @intFolderRSN
AND FolderProcessAttempt.AttemptRSN = 
    ( SELECT max(FolderProcessAttempt.AttemptRSN) 
        FROM FolderProcess, FolderProcessAttempt
       WHERE FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
         AND FolderProcess.ProcessCode = @intProcessCode
         AND FolderProcessAttempt.FolderRSN = @intFolderRSN )

SELECT @strSeeReference = 
CASE @intAttemptCode
   WHEN 10002 THEN 'See Reasons for Denial'
   WHEN 10003 THEN 'See Conditions of Approval'
   WHEN 10006 THEN 'See Findings of Fact'
   WHEN 10007 THEN 'See Findings of Fact'
   WHEN 10011 THEN 'See Requirements for Permit Release'
   WHEN 10017 THEN ' '
   WHEN 10018 THEN ' '
   WHEN 10020 THEN 'See Reasons for Denial w/o Prejudice'
   WHEN 10046 THEN 'See Determination Findings'
   WHEN 10047 THEN 'See Determination Findings'
   ELSE 'x'
END

RETURN @strSeeReference
END

GO
