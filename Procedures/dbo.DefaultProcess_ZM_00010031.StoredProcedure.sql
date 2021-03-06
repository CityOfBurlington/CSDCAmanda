USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZM_00010031]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZM_00010031]
@ProcessRSN numeric(10), @FolderRSN numeric(10), @UserId char(128)
as
exec RsnSetLock
DECLARE @NextRSN numeric(10) 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN numeric(10) 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN numeric(10) 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 
/* ZM Agenda Management (10031) version 1 JA 12/2010 */

DECLARE @intAttemptResult int 
DECLARE @intFolderStatus int
DECLARE @intBoardSubCode int
DECLARE @intChecklistCount int 
DECLARE @intChecklistCodeYes int
DECLARE @varMeetingDateTime varchar(100)
DECLARE @varFolderLog varchar(150)
DECLARE @intFolderInfoCount int
DECLARE @intLoopCounter int

/* Get attempt result */

SELECT @intAttemptResult = FolderProcessAttempt.ResultCode 
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN ) 

SELECT @intFolderStatus = Folder.StatusCode, 
       @intBoardSubCode = Folder.SubCode
  FROM Folder 
 WHERE Folder.FolderRSN = @FolderRSN 

/* Close Agenda - perform checks, delete any null FolderRSN Info fields, and 
   reset White Board log. */

IF @intAttemptResult = 10068                    /* Close Agenda */
BEGIN
   SELECT @intChecklistCount = COUNT(*) 
     FROM FolderProcessChecklist  
    WHERE FolderProcessChecklist.ProcessRSN = @ProcessRSN 
      AND FolderProcessChecklist.Passed = 'Y'

   IF @intChecklistCount = 0 
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please set a Meeting Type checklist to Yes.', 16, -1)
      RETURN
   END

   IF @intChecklistCount > 1 
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Only one Meeting Type checklist may be set to Yes. Please correct.', 16, -1)
      RETURN
   END

   IF @intChecklistCount = 0 
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please set a Meeting Type checklist to Yes.', 16, -1)
      RETURN
   END

   SELECT @intChecklistCodeYes = FolderProcessChecklist.ChecklistCode /* Not used */
     FROM FolderProcessChecklist  
    WHERE FolderProcessChecklist.ProcessRSN = @ProcessRSN 
      AND FolderProcessChecklist.Passed = 'Y'

   UPDATE Folder 
      SET Folder.StatusCode = 10052             /* Agenda Closed */
    WHERE Folder.FolderRSN = @FolderRSN 

   DELETE FolderInfo 
     FROM FolderInfo
   INNER JOIN Folder ON FolderInfo.FolderRSN = Folder.FolderRSN
        WHERE Folder.FolderRSN = @FolderRSN 
          AND FolderInfo.InfoCode BETWEEN 10082 AND 10119 
          AND FolderInfo.InfoValue IS NULL 

   EXECUTE dbo.usp_Zoning_Order_FolderInfo_ZM_Folder @FolderRSN 

   EXECUTE dbo.usp_Zoning_Update_Agenda_Log_ZM_Folder @FolderRSN
END

/* Reopen Agenda - reset FolderStatus and add blank FolderRSN Info fields 
   where needed. */

IF @intAttemptResult = 10069                    /* Reopen Agenda */
BEGIN
   UPDATE Folder 
      SET Folder.StatusCode = 10050             /* Agenda Active */
    WHERE Folder.FolderRSN = @FolderRSN 

   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_ZM_Folder @FolderRSN , @UserID 
END

/* Cancel Meeting - Update Folder Status and delete any null FolderRSN Info fields. */

IF @intAttemptResult = 10070                    /* Cancel Meeting */
BEGIN
   UPDATE Folder 
      SET Folder.StatusCode = 10054, 
          Folder.FolderCondition = CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000), Folder.FolderCondition)) + ' -> Meeting Cancelled (' + CONVERT(char(11), getdate()) + ')')) 
 WHERE Folder.FolderRSN = @FolderRSN 

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Meeting Cancelled',
           FolderProcess.EndDate = getdate()
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN

    DELETE FolderInfo 
      FROM FolderInfo
    INNER JOIN Folder ON FolderInfo.FolderRSN = Folder.FolderRSN
         WHERE Folder.FolderRSN = @FolderRSN 
           AND FolderInfo.InfoCode BETWEEN 10082 AND 10119 
           AND FolderInfo.InfoValue IS NULL 
END

/* Re-open process for all attempt results except Cancel Meeting (10070) */

IF @intAttemptResult <> 10070
BEGIN
   UPDATE FolderProcess
 SET FolderProcess.StatusCode = 1, 
          FolderProcess.ScheduleDate = getdate(),
          FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
          FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL
    WHERE FolderProcess.ProcessRSN = @ProcessRSN
      AND FolderProcess.FolderRSN = @FolderRSN
END

GO
