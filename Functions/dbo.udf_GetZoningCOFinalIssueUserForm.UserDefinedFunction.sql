USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningCOFinalIssueUserForm]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningCOFinalIssueUserForm](@intFolderRSN INT) 
RETURNS varchar(100)
AS
BEGIN
   /* Returns the FolderProcess.SignOffUser for Certificate of Occupancy processing. 
      Returns the user for the highest phase where the PCO was issued. 
      Used by Infomaker CO report form. 
      Can not use Folder.StatusCode to differentiate phasing because the 
      Folder.StatusCode becomes Final CO Issued (10008) upon issuance. */

   DECLARE @intNumberofPhases int
   DECLARE @varIssueUser varchar(100)

   SET @intNumberofPhases = 1 

   SELECT @intNumberofPhases = CAST(ROUND(ISNULL(FolderInfo.InfoValueNumeric, 0), 0) AS INT)
     FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @intFolderRSN 
      AND FolderInfo.InfoCode = 10081 

   IF @intNumberofPhases > 1     /* Phased Projects */
   BEGIN
      SELECT @varIssueUser = ValidUser.UserName + ', ' + ISNULL(NULLIF(ValidUser.UserTitle, ' '), 'Code Enforcement')
        FROM FolderProcess, ValidUser 
       WHERE FolderProcess.SignOffUser = ValidUser.UserID 
         AND FolderProcess.FolderRSN = @intFolderRSN
         AND FolderProcess.ProcessRSN = 
             ( SELECT MAX(FolderProcess.ProcessRSN) 
                 FROM FolderProcess, FolderProcessAttempt 
                WHERE FolderProcess.FolderRSN = @intFolderRSN 
                  AND FolderProcess.ProcessCode = 10030          /* Phased Certificate of Occupancy */
                  AND FolderProcess.StatusCode = 2               /* Closed */
                  AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN 
                  AND FolderProcessAttempt.ResultCode = 10066 )  /* Approved for Phase CO */
   END
   ELSE       /* Single Phase Projects */
   BEGIN
      SELECT @varIssueUser = ValidUser.UserName + ', ' + ISNULL(NULLIF(ValidUser.UserTitle, ' '), 'Code Enforcement')
        FROM FolderProcess, ValidUser 
       WHERE FolderProcess.SignOffUser = ValidUser.UserID 
         AND FolderProcess.FolderRSN = @intFolderRSN
         AND FolderProcess.ProcessCode = 10001           /* Certificate of Occupancy */
   END

   RETURN @varIssueUser 
END

GO
