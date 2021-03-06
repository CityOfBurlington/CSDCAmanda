USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010005]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010005]
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
/* Project Decision (10005) version 3 */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @StatusCode int
DECLARE @NextStatusCode int
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @InDate datetime
DECLARE @intErosionControlInfoCount int
DECLARE @varErosionControlInfoValue varchar(4)
DECLARE @AdminDecisionDate datetime
DECLARE @DRBDecisionDate datetime
DECLARE @DecisionDate datetime
DECLARE @ExpiryDate datetime
DECLARE @PermitExpiryDate datetime 
DECLARE @intPreReleaseCondProcess int
DECLARE @PermitConditionsDoc int
DECLARE @ReasonsforDenialDoc int
DECLARE @FindingsofFactDoc int
DECLARE @DecisionLetterDoc int
DECLARE @PermitPickedupInfoOrder int
DECLARE @PermitPickedupInfoField int
DECLARE @PermitPickedupInfoValue varchar(10)
DECLARE @AdminReviewClock int
DECLARE @DRBFindingsClock int
DECLARE @RCLastAttemptCode int
DECLARE @SchedulerClock int
DECLARE @SchedulerClockStartDate datetime
DECLARE @SchedulerClockStatus varchar(20)
DECLARE @SchedulerClockDayDiff int

/* Get Attempt Result, and other folder values. Get Folder Type for the parent folder, 
   if it exists. */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

SELECT @FolderType = Folder.FolderType, 
       @StatusCode = Folder.StatusCode, 
       @InDate = Folder.InDate, 
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

SELECT @FindingsofFactDoc = count(*)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @FolderRSN
   AND FolderDocument.DocumentCode = 10005

SELECT @PermitConditionsDoc = count(*)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @FolderRSN
   AND FolderDocument.DocumentCode = 10008

SELECT @ReasonsforDenialDoc = count(*)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @FolderRSN
   AND FolderDocument.DocumentCode = 10010

SELECT @DecisionLetterDoc = count(*)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @FolderRSN
   AND FolderDocument.DocumentCode = 10012

/* Folder status must be In Review for process to run. User must 
   restart the folder clock using the Review Clock process. */

IF @StatusCode <> 10001
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('You must first restart the clock using Review Clock in order to proceed.', 16, -1)
   RETURN
END

/* Check for existence of DRB Findings, Admin Review, and Scheduler folder clocks, 
   and ProcessInfo Waive Right to Appeal Option. Get the last Review Clock attempt 
   result to enable administrative denials of incomplete applications. */

SELECT @DRBFindingsClock = COUNT(*)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'DRB Findings'

SELECT @AdminReviewClock = COUNT(*)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Admin Review'

SELECT @SchedulerClock = COUNT(*)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Scheduler'

SELECT @SchedulerClockStatus = FolderClock.Status 
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Scheduler'

SELECT @RCLastAttemptCode = FolderProcessAttempt.ResultCode
  FROM Folder, FolderProcess, FolderProcessAttempt
 WHERE Folder.FolderRSN = FolderProcess.FolderRSN
   AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
   AND FolderProcess.ProcessCode = 10007
   AND Folder.FolderRSN = @FolderRSN
   AND FolderProcessAttempt.AttemptRSN = 
     ( SELECT max(FolderProcessAttempt.AttemptRSN) 
         FROM FolderProcess, FolderProcessAttempt
        WHERE FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
          AND FolderProcess.ProcessCode = 10007
          AND FolderProcessAttempt.FolderRSN = @FolderRSN )

/* Check to insure entry of Erosion Control Plan Required Info field. 
   If field is 'Yes' then a stormwater bill will be generated. 
   The ultimate plan is for 'Yes' to trigger initialization of a stormwater folder. */

   SELECT @intErosionControlInfoCount = COUNT(*)
     FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @FolderRSN 
      AND FolderInfo.InfoCode = 10077

   IF @intErosionControlInfoCount > 0 
   BEGIN
      SELECT @varErosionControlInfoValue = FolderInfo.InfoValueUpper
        FROM FolderInfo 
       WHERE FolderInfo.FolderRSN = @FolderRSN 
         AND FolderInfo.InfoCode = 10077 

      IF @varErosionControlInfoValue IS NULL
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('Please enter Y/N for Erosion Control Plan Required (Info) to proceed', 16, -1)
         RETURN
      END
   END

/* Check to make sure the administrative decision date info field has been entered, 
   and set appeal period expiry (expiration) date to 15 days. */

IF @Subcode = 10041                           /* Administrative review */
BEGIN 
   SELECT @AdminDecisionDate = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = 10055         /* Admin Decision Date */

   IF @AdminDecisionDate IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter the Admin Decision Date (Info) to proceed', 16, -1)
      RETURN
   END

   SELECT @DecisionDate = @AdminDecisionDate
   SELECT @ExpiryDate = DATEADD(day, 15, @DecisionDate)   /* Appeal period for administrative review */
END

/* Check to make sure the DRB decision date info field has been entered, Waive Right to Appeal Option 
   has been set, and set appeal period expiry (expiration) date to 30 days. */

IF @SubCode = 10042  /* DRB review */
BEGIN
   SELECT @DRBDecisionDate = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = 10049             /* DRB Decision Date */

   IF @DRBDecisionDate IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter the DRB Decision Date (Info) to proceed', 16, -1)
      RETURN
   END

   SELECT @DecisionDate = @DRBDecisionDate
   SELECT @ExpiryDate = DATEADD(day, 30, @DecisionDate)  /* Appeal period expiration */
END

/* Set next Folder.StatusCode according to attempt result. */

SELECT @NextStatusCode = dbo.udf_GetZoningDecisionNextStatusCode(@FolderRSN, @AttemptResult)

/* Set review decision, update folder status, set folder decision and appeal period 
   expiration dates, reopen process for permit printing */

IF @AttemptResult = 10003                   /* Decision: Approved */
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Decision: Approved (' + CONVERT(char(11), @DecisionDate) + ')'))
 WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'APP',
           FolderProcess.ScheduleDate = getdate(),
           FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'APP (' + CONVERT(char(11), @DecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
    WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

IF @AttemptResult = 10011                  /* Decision: Approved with Pre-Release Conditions*/
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Decision: Approved with Pre-Release Conditions (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'APP-PRC',
           FolderProcess.ScheduleDate = getdate(),
           FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessRSN = @ProcessRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'APP-PRC (' + CONVERT(char(11), @DecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
      FROM FolderProcessAttempt
           WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

   SELECT @intPreReleaseCondProcess = dbo.udf_CountProcesses(@FolderRSN, 10006)

   IF @intPreReleaseCondProcess > 0 
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, FolderProcess.EndDate = NULL
       WHERE FolderProcess.FolderRSN = @FolderRSN 
         AND FolderProcess.ProcessCode = 10006
   END
END

IF @AttemptResult = 10002                     /* Decision: Denied */
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
  Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId, 
          Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Decision: Denied (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'DEN',
           FolderProcess.ScheduleDate = getdate(),
       FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
  FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'DEN (' + CONVERT(char(11), @DecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
   ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

IF @AttemptResult = 10020                  /* Decision: Denied w/o Prejudice */
BEGIN
  UPDATE Folder
     SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate =  @ExpiryDate, 
   Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
         Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Decision: Denied without Prejudice (' + CONVERT(char(11), @DecisionDate) + ')'))
   WHERE Folder.FolderRSN = @FolderRSN

 UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'DWP',
           FolderProcess.ScheduleDate = getdate(),
           FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN

    UPDATE FolderProcessAttempt
    SET FolderProcessAttempt.AttemptComment = 'DWP (' + CONVERT(char(11), @DecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
     AND FolderProcessAttempt.AttemptRSN = 
        ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )
END

/* Add decision Documents */

IF @FindingsofFactDoc = 0 AND @SubCode = 10042
BEGIN 
   SELECT @NextDocumentRSN = @NextDocumentRSN + 1
   INSERT INTO FolderDocument
             ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
               DisplayOrder, StampDate, StampUser, LinkCode )
      VALUES ( @FolderRSN, 10005, 1, @NextDocumentRSN, 11, getdate(), @UserID, 1 )  
END

IF @AttemptResult IN (10003, 10011)
BEGIN
   IF @PermitConditionsDoc = 0 AND @FolderType <> 'ZH'
   BEGIN 
      SELECT @NextDocumentRSN = @NextDocumentRSN + 1
      INSERT INTO FolderDocument
                ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
                  DisplayOrder, StampDate, StampUser, LinkCode )
         VALUES ( @FolderRSN, 10008, 1, @NextDocumentRSN, 10, getdate(), @UserID, 1 )  
   END
END

IF @AttemptResult IN (10002, 10020)
BEGIN
   IF @ReasonsforDenialDoc = 0 AND @FolderType <> 'ZH'
   BEGIN 
      SELECT @NextDocumentRSN = @NextDocumentRSN + 1
      INSERT INTO FolderDocument
                ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
                  DisplayOrder, StampDate, StampUser, LinkCode )
         VALUES ( @FolderRSN, 10010, 1, @NextDocumentRSN, 10, getdate(), @UserID, 1 )  
   END
END

/* Add Zoning Decision Letter document to notify applicant. Used only for DRB 
   COA and Basic decisions at this time, but it will also work for administrative 
   decisions. To add admin, add SubCode 10041 to the IF statement. For ZH folders, 
   this document is added by Info Validation of DRB Deliberative Decision (10036). */

IF @DecisionLetterDoc = 0 AND @SubCode = 10042
BEGIN 
   SELECT @NextDocumentRSN = @NextDocumentRSN + 1
   INSERT INTO FolderDocument
      ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
               DisplayOrder, StampDate, StampUser, LinkCode )
      VALUES ( @FolderRSN, 10012, 1, @NextDocumentRSN, 40, getdate(), @UserID, 1 )  
END

/* Check for existence of FolderInfo Permit Picked Up (10023), insert if needed, 
   and code. */

SELECT @PermitPickedupInfoField = dbo.udf_FolderInfoFieldExists(@FolderRSN, 10023) 
SELECT @PermitPickedupInfoOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@FolderRSN, 10023)
SELECT @PermitPickedupInfoValue = dbo.udf_GetZoningPermitPickedUp(@FolderRSN)

IF @PermitPickedupInfoField = 0 
BEGIN
   INSERT INTO FolderInfo
             ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
               InfoValue, InfoValueUpper, 
               StampDate, StampUser, Mandatory, ValueRequired )
      VALUES ( @FolderRSN, 10023,  @PermitPickedupInfoOrder, 'Y', 
               @PermitPickedupInfoValue, UPPER(@PermitPickedupInfoValue), 
               getdate(), @UserID, 'N', 'N' )
END
ELSE
BEGIN
   UPDATE FolderInfo
      SET FolderInfo.InfoValue = @PermitPickedupInfoValue, 
          FolderInfo.InfoValueUpper = UPPER(@PermitPickedupInfoValue) 
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = 10023
END

/* Update FolderInfo Project Manager. */

   EXECUTE dbo.usp_Zoning_Update_Project_Manager @FolderRSN, @UserID

/* Update FolderInfo Permit Expiration Date and Construction Start Deadline. */

   EXECUTE dbo.usp_Zoning_Permit_Expiration_Dates @FolderRSN, @DecisionDate

/* Insert FolderInfo Expiration Notification Generated. */

   EXECUTE dbo.usp_Zoning_Permit_Expiration_Notification @FolderRSN, @UserID 

/* Decision Rendered:
   Record Appeal period start and end in the Project Decision process (10005).
   Close Review Path (10000) and record total gross review time - InDate and DecisionDate.
   Close Review Clock (10007). 
   Stop the Admin Review and DRB Findings folder clocks. 
   Stop the Scheduler clock if it is still running. It is supposed to stop when a 
   DRB Meeting Date is entered (Info), but the date might not have been entered. */

UPDATE FolderProcess
   SET FolderProcess.Startdate = @DecisionDate,
       FolderProcess.EndDate = @ExpiryDate
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessRSN = @ProcessRSN

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 2, FolderProcess.StartDate = @InDate, 
       FolderProcess.EndDate = @DecisionDate, FolderProcess.AssignedUser = @UserID, 
       FolderProcess.SignOffUser = @UserID
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10000             /* Review Path */

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 2
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10007             /* Review Clock */

IF @SubCode = 10041 AND @AdminReviewClock > 0
BEGIN
   UPDATE FolderClock
      SET FolderClock.Status = 'Stopped'
    WHERE FolderClock.FolderRSN = @FolderRSN
      AND FolderClock.FolderClock = 'Admin Review'
END

IF @SubCode = 10042 AND @DRBFindingsClock > 0
BEGIN
   UPDATE FolderClock
      SET FolderClock.Status = 'Stopped'
    WHERE FolderClock.FolderRSN = @FolderRSN
      AND FolderClock.FolderClock = 'DRB Findings'
END

IF @WorkCode = 10003 AND @SchedulerClock > 0 AND @SchedulerClockStatus = 'Running'
BEGIN
   SELECT @SchedulerClockStartDate = @InDate

   SELECT @SchedulerClockDayDiff = DATEDIFF(day, @SchedulerClockStartDate, @DecisionDate)

      UPDATE FolderClock
         SET FolderClock.Status = 'Stopped', 
             FolderClock.Counter = @SchedulerClockDayDiff, 
             FolderClock.StartDate= @DecisionDate 
       WHERE FolderClock.FolderRSN = @FolderRSN
         AND FolderClock.FolderClock = 'Scheduler'
END

GO
