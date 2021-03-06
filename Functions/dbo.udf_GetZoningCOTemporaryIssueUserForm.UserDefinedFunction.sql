USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningCOTemporaryIssueUserForm]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningCOTemporaryIssueUserForm](@intFolderRSN INT) 
RETURNS varchar(100)
AS
BEGIN
   /* Returns the FolderProcessAttaempt.AttemptBy for Certificate of Occupancy processing. 
      Returns the user for the highest phase where theTCO was issued. 
      Used by Infomaker CO report form. 
      Can not use Folder.StatusCode to differentiate phasing because the 
      Folder.StatusCode becomes Final CO Issued (10008) upon issuance. */

   DECLARE @intNumberofPhases int
   DECLARE @intLastPCOProcessRSN int
   DECLARE @varIssueUser varchar(100)

   SET @intNumberofPhases = 1 

   SELECT @intNumberofPhases = CAST(ROUND(ISNULL(FolderInfo.InfoValueNumeric, 0), 0) AS INT)
     FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @intFolderRSN 
      AND FolderInfo.InfoCode = 10081 

   IF @intNumberofPhases > 1     /* Phased Projects */
   BEGIN
      SELECT @intLastPCOProcessRSN = MAX(FolderProcess.ProcessRSN) 
        FROM FolderProcess, FolderProcessAttempt 
       WHERE FolderProcess.FolderRSN = @intFolderRSN 
         AND FolderProcess.ProcessCode = 10030          /* Phased Certificate of Occupancy */
         AND FolderProcess.StatusCode = 10004           /* Temp CO Issued */
         AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN 
         AND FolderProcessAttempt.ResultCode = 10029    /* Approved for Temp CO */

      SELECT @varIssueUser = ValidUser.UserName + ', ' + ISNULL(NULLIF(ValidUser.UserTitle, ' '), 'Code Enforcement')
        FROM FolderProcessAttempt, ValidUser 
       WHERE FolderProcessAttempt.FolderRSN = @intFolderRSN
         AND FolderProcessAttempt.ProcessRSN = @intLastPCOProcessRSN
         AND FolderProcessAttempt.AttemptBy = ValidUser.UserID 
         AND FolderProcessAttempt.AttemptRSN = 
             ( SELECT MAX(FolderProcessAttempt.AttemptRSN)
                 FROM FolderProcessAttempt 
                WHERE FolderProcessAttempt.FolderRSN = @intFolderRSN
                  AND FolderProcessAttempt.ProcessRSN = @intLastPCOProcessRSN
                  AND FolderProcessAttempt.ResultCode = 10029 ) /* Approved for Temp C of O */
   END
   ELSE       /* Single Phase Projects */
   BEGIN
      SELECT @varIssueUser = ValidUser.UserName + ', ' + ISNULL(NULLIF(ValidUser.UserTitle, ' '), 'Code Enforcement')
        FROM FolderProcess, FolderProcessAttempt, ValidUser 
       WHERE FolderProcess.FolderRSN = @intFolderRSN
         AND FolderProcess.ProcessCode = 10001                  /* Certificate of Occupancy */
         AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN 
         AND FolderProcessAttempt.AttemptBy = ValidUser.UserID 
         AND FolderProcessAttempt.AttemptRSN = 
             ( SELECT MAX(FolderProcessAttempt.AttemptRSN)
                 FROM FolderProcessAttempt, FolderProcess
                WHERE FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
                  AND FolderProcessAttempt.ResultCode = 10029   /* Approved for Temp C of O */
                  AND FolderProcess.FolderRSN = @intFolderRSN )
   END

   RETURN @varIssueUser 
END

GO
