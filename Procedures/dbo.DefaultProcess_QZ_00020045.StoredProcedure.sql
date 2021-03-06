USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QZ_00020045]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QZ_00020045]
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
/* Zoning Review Request (20045) version 1 */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int

DECLARE @TotalChecklistCheck int
DECLARE @DRBCheckListCheck int
DECLARE @AdminCheckListCheck int
DECLARE @DRBCListValue varchar(1)
DECLARE @AdminCListValue varchar(1)
DECLARE @ReviewBody varchar(20)

DECLARE @ZRRequestDate  datetime
DECLARE @ZRDecisionDate datetime
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

/* Get checklist values. */

SELECT @DRBCListValue = FolderProcessChecklist.Passed
  FROM FolderProcessChecklist
 WHERE FolderProcessChecklist.ProcessRSN = @processRSN
   AND FolderProcessChecklist.ChecklistCode = 20036

SELECT @AdminCListValue = FolderProcessChecklist.Passed
  FROM FolderProcessChecklist
 WHERE FolderProcessChecklist.ProcessRSN = @processRSN
   AND FolderProcessChecklist.ChecklistCode = 20037

/* Check to make sure only one checklist item is selected. */

IF @DRBCListValue = 'Y'   SELECT @DRBChecklistCheck = 1
IF @AdminCListValue = 'Y' SELECT @AdminChecklistCheck = 1

SELECT @TotalChecklistCheck = ISNULL(@DRBChecklistCheck, 0) + 
                              ISNULL(@AdminChecklistCheck, 0)

IF @TotalChecklistCheck <> 1
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 1, FolderProcess.StartDate = NULL, 
          FolderProcess.EndDate = NULL, FolderProcess.ScheduleDate = NULL, 
          FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL
    WHERE ProcessRSN = @ProcessRSN
 
   DELETE FROM FolderProcessAttempt
          WHERE ProcessRSN = @ProcessRSN
            AND AttemptRSN = 
                (SELECT max(AttemptRSN)
                   FROM FolderProcessAttempt
                  WHERE ProcessRSN = @ProcessRSN)
 
   COMMIT TRANSACTION
   BEGIN TRANSACTION
 
   RAISERROR ('One checklist item must be set to Yes. Please correct.', 16, -1)
   RETURN
END

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
   expiry date to decision date plus 15 or 30 days. */

SELECT @ZRRequestDate = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20057

SELECT @ZRDecisionDate = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20058

IF @ZRDecisionDate IS NULL
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter the Zoning Review Decision Date Info field to continue.', 16, -1)
   RETURN
END

IF @DRBCListValue = 'Y'   SELECT @ExpiryDate = @ZRDecisionDate + 30, 
                                 @ReviewBody = 'DRB'
IF @AdminCListValue = 'Y' SELECT @ExpiryDate = @ZRDecisionDate + 15, 
                                 @ReviewBody = 'Administrative'

/* Request Approved attempt result */

IF @AttemptResult = 20092
BEGIN

   UPDATE Folder
      SET Folder.WorkCode = 20115, Folder.IssueDate = @ZRDecisionDate, 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Zoning Approved Request (' + CONVERT(char(11), @ZRDecisionDate) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = @ReviewBody + ' Decision: Approved',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Decision: Approved (' + CONVERT(char(11), @ZRDecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   UPDATE FolderInfo
      SET FolderInfo.InfoValue = 'Zoning Review - Approved', 
          FolderInfo.InfoValueUpper = UPPER('Zoning Review - Approved')
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20068

END    /* end of Request Approved attempt result */

/* Request Denied attempt result */

IF @AttemptResult = 20093
BEGIN

   UPDATE Folder
      SET Folder.WorkCode = 20116, Folder.IssueDate = @ZRDecisionDate, 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Zoning Denied Request (' + CONVERT(char(11), @ZRDecisionDate) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = @ReviewBody + ' Decision: Denied',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Decision: Denied (' + CONVERT(char(11), @ZRDecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   UPDATE FolderInfo
      SET FolderInfo.InfoValue = 'Zoning Review - Denied', 
          FolderInfo.InfoValueUpper = UPPER('Zoning Review - Denied')
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
