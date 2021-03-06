USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QZ_00020043]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QZ_00020043]
@ProcessRSN int, @FolderRSN int, @UserId char(128)
as
exec RsnSetLock
DECLARE @NextRSN int 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN int 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN int 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 
/* Grandfathering Request (20043) version 1 */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int

DECLARE @GFRequestDate  datetime
DECLARE @GFDecisionDate datetime
DECLARE @ExpiryDate datetime

DECLARE @InvestigationProcessOrder int
DECLARE @InitiateAppealProcess int
DECLARE @InitiateAppealProcessOrder int
DECLARE @InitiateAppealProcessAttempt int

/* Get Attempt Result */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @processRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

/* Get Folder Type, Folder Status, Initialization Date, SubCode, WorkCode values. */

SELECT @FolderType = Folder.FolderType, 
       @FolderStatus = Folder.StatusCode,
       @InDate = Folder.InDate,
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @folderRSN

/* Set Initiate Appeal process orders, and check for existence */

SELECT @InvestigationProcessOrder = ISNULL(FolderProcess.DisplayOrder, 100)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20046

SELECT @InitiateAppealProcessOrder = @InvestigationProcessOrder + 60

SELECT @InitiateAppealProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20050

/* Get Grandfathering Request and Decision Date Info field values. Set appeal period 
   expiry date to decision date plus 15 days. */

SELECT @GFRequestDate = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20053

SELECT @GFDecisionDate = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20054

IF @GFDecisionDate IS NULL
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter the Grandfathering Decision Date Info field to continue.', 16, -1)
   RETURN
END

SELECT @ExpiryDate = @GFDecisionDate + 15

/* Request Approved attempt result */

IF @AttemptResult = 20092
BEGIN

   UPDATE Folder
      SET Folder.WorkCode = 20115, Folder.IssueDate = @GFDecisionDate, 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Grandfathering Request Approved (' + CONVERT(char(11), @GFDecisionDate) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Decision: Approved',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Decision: Approved (' + CONVERT(char(11), @GFDecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   UPDATE FolderInfo
      SET FolderInfo.InfoValue = 'Grandfathering - Approved', 
          FolderInfo.InfoValueUpper = UPPER('Grandfathering - Approved')
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20068

END    /* end of Request Approved attempt result */


/* Request Denied attempt result */

IF @AttemptResult = 20093
BEGIN

   UPDATE Folder
      SET Folder.WorkCode = 20116, Folder.IssueDate = @GFDecisionDate, 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Grandfathering Request Denied (' + CONVERT(char(11), @GFDecisionDate) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Decision: Denied',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Decision: Denied (' + CONVERT(char(11), @GFDecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   UPDATE FolderInfo
      SET FolderInfo.InfoValue = 'Grandfathering - Denied', 
          FolderInfo.InfoValueUpper = UPPER('Grandfathering - Denied')
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20068

END    /* end of Request Denied attempt result */

/* Close processes; add or reopen Initiate Appeal process. */

IF @AttemptResult IN(20092, 20093)
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 2, 
          FolderProcess.EndDate = getdate(), 
          FolderProcess.BaseLineEndDate = getdate(), 
          FolderProcess.SignOffUser = @UserID
    WHERE FolderProcess.ProcessCode IN(20042, 20043, 20044, 20045, 20046, 20047, 20051, 20052)
      AND FolderProcess.FolderRSN = @folderRSN

   IF @InitiateAppealProcess = 0
   BEGIN
      SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

   INSERT INTO FolderProcess
            ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
              ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
              AssignedUser, DisplayOrder,
              PrintFlag, MandatoryFlag, StampDate, StampUser )
      VALUES ( @NextProcessRSN, @folderRSN, 20050, 80, 1,
               getdate(), (getdate() + 180), getdate(), (getdate() + 180), 
               @UserID, @InitiateAppealProcessOrder, 
               'Y', 'Y', getdate(), @UserID )
   END

   IF @InitiateAppealProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 20050
         AND FolderProcess.FolderRSN = @folderRSN
   END
END

GO
