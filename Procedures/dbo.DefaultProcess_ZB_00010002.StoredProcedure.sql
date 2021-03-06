USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010002]    Script Date: 9/9/2013 9:56:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010002]
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
/* Appeal to DRB (10002) version 4 */

DECLARE @AttemptResult int
DECLARE @DecisionDate datetime
DECLARE @FolderType varchar(4)
DECLARE @StatusCode int
DECLARE @InDate datetime
DECLARE @ExpiryDate datetime
DECLARE @PermitExpiryDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @NextStatusCode int
DECLARE @FindingsofFactDoc int
DECLARE @FindingsofFactGen datetime
DECLARE @DecisionProcessRSN int
DECLARE @DecisionProcessCode int
DECLARE @DecisionAttemptResult int
DECLARE @DecisionOverturnAttemptResult int
DECLARE @DecisionOverturnProcessText varchar(40)
DECLARE @NextDecisionAttemptRSN int
DECLARE @DecisionText varchar(100)
DECLARE @PermitPickedupInfoOrder int
DECLARE @PermitPickedupInfoField int
DECLARE @PermitPickedupInfoValue varchar(10)
DECLARE @AppealFindingsClock int
DECLARE @SchedulerClock int
DECLARE @SchedulerClockStartDate datetime
DECLARE @SchedulerClockStatus varchar(20)
DECLARE @SchedulerClockDayDiff int
DECLARE @InitiateAppealAttemptResult int

/* Get Attempt Result, Folder and Parent folder info */

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

SELECT @AppealFindingsClock = COUNT(*)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Appeal Fdngs'

SELECT @SchedulerClock = COUNT(*)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Scheduler'

SELECT @SchedulerClockStatus = FolderClock.Status 
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Scheduler'

SELECT @FindingsofFactDoc = count(*)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @FolderRSN
   AND FolderDocument.DocumentCode = 10005

SELECT @FindingsofFactGen = FolderDocument.DateGenerated
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @FolderRSN
   AND FolderDocument.DocumentCode = 10005

/* Folder status must be Appealed to DRB for process to run. This forces the 
   user to restart the folder clock using the Appeal Clock process. */

IF @StatusCode <> 10009
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('You must first restart the clock using Appeal Clock in order to proceed.', 16, -1)
   RETURN
END

/* Get Decision process attempt result. Set a reversed Decision process attempt 
   result code. The reversed decision code will be inserted into the decision 
   process by the Grant Appeal (overturn) attempt result. */

SELECT @DecisionProcessCode = dbo.udf_GetZoningDecisionProcessCode(@FolderRSN)

IF @SubCode = 10041 
   SELECT @DecisionAttemptResult = dbo.udf_GetZoningDecisionAttemptCode(@FolderRSN)

SELECT @DecisionText = dbo.udf_GetZoningDecisionAttemptText(@FolderRSN, @DecisionAttemptResult)

SELECT @NextDecisionAttemptRSN = dbo.udf_GetZoningDecisionNextAttemptRSN(@FolderRSN) 

SELECT @DecisionProcessRSN = dbo.udf_GetZoningDecisionProcessRSN(@FolderRSN)

SELECT @DecisionOverturnAttemptResult = dbo.udf_GetZoningDecisionOverturnAttemptResult(@FolderRSN)

SELECT @DecisionOverturnProcessText = dbo.udf_GetZoningDecisionOverturnAttemptText(@FolderRSN)

/* Check to make sure the Info field DRB Appeal Decision Date has been entered. 
   If it is null, issue error message and end process. Check to insure that 
   Folder.SubCode is 10041 (Admin Review), or a ZL folder. */

SELECT @DecisionDate = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
 AND FolderInfo.InfoCode = 10056        /* DRB Appeal Decision Date */

IF @DecisionDate IS NULL
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter the DRB Appeal Decision Date (Info) to proceed', 16, -1)
   RETURN
END

IF @SubCode = 10042 AND @FolderType <> 'ZL'
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('The Folder Sub must be set to Administrative Review, or is a Misc Appeal (ZL folder) for process to run', 16, -1)
   RETURN
END

/* Set appeal period expiration date (30 days for DRB decisions). */

SELECT @ExpiryDate = DATEADD(day, 30, @DecisionDate)

/* Record review decision, and update folder status */

IF @AttemptResult = 10006        /* Uphold Administrative Decision */
BEGIN
   IF @FolderType = 'ZL'
      SELECT @NextStatusCode = 10003
   ELSE SELECT @NextStatusCode = dbo.udf_GetZoningDecisionNextStatusCode(@FolderRSN, @DecisionAttemptResult)

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId, 
          Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Appeal Decision: Uphold Staff ' + rtrim(@DecisionText) + ' (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Appeal Denied',
           FolderProcess.StartDate = @DecisionDate,
           FolderProcess.EndDate = @ExpiryDate
     WHERE FolderProcess.FolderRSN = @FolderRSN
  AND FolderProcess.ProcessRSN = @ProcessRSN
END

IF @AttemptResult = 10007        /* Overturn Administrative Decision */
BEGIN
   IF @FolderType = 'ZL' SELECT @NextStatusCode = 10002
   ELSE SELECT @NextStatusCode = dbo.udf_GetZoningDecisionNextStatusCode(@FolderRSN, @DecisionOverturnAttemptResult)

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Appeal Decision: Overturn Staff ' + rtrim(@DecisionText) + ' (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Appeal Granted',
           FolderProcess.StartDate = @DecisionDate,
           FolderProcess.EndDate = @ExpiryDate
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN

   IF @DecisionOverturnAttemptResult > 0 AND @FolderType <> 'ZL'
   BEGIN
      INSERT INTO FolderProcessAttempt
                ( AttemptRSN, FolderRSN, ProcessRSN, 
                  ResultCode, 
                  AttemptComment, 
                  AttemptBy, AttemptDate, StampUser, StampDate )
         VALUES ( @NextDecisionAttemptRSN, @FolderRSN, @DecisionProcessRSN, 
                  @DecisionOverturnAttemptResult, 
                  'Overturned on DRB Appeal (' + CONVERT(CHAR(11), @DecisionDate) + ')', 
                  @UserID, getdate(), @UserID, getdate() )

     UPDATE FolderProcess
        SET FolderProcess.ProcessComment = @DecisionOverturnProcessText
       FROM FolderProcess
      WHERE FolderProcess.FolderRSN = @FolderRSN
        AND FolderProcess.ProcessRSN = @DecisionProcessRSN
        AND FolderProcess.ProcessCode = @DecisionProcessCode

     IF @DecisionAttemptResult = 10011   /* App with Pre-Release Conditions */
 BEGIN
    UPDATE FolderProcess
           SET StatusCode = 2, EndDate = getdate() 
         WHERE FolderProcess.FolderRSN = @FolderRSN
           AND FolderProcess.ProcessCode = 10006
           AND FolderProcess.StatusCode = 1 
     END
   END
END

/* Add Findings of Fact document */

IF @FindingsofFactDoc = 0 OR @FindingsofFactGen IS NOT NULL
BEGIN
  SELECT @NextDocumentRSN = @NextDocumentRSN + 1
  INSERT INTO FolderDocument
            ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
      DisplayOrder, StampDate, StampUser, LinkCode )
     VALUES ( @FolderRSN, 10005, 1, @NextDocumentRSN, 12, getdate(), @UserID, 1 )
END

/* Update Project Manager Info field */

EXECUTE dbo.usp_Zoning_Update_Project_Manager @FolderRSN, @UserID

/* Set value for Permit Picked Up (InfoCode = 10023) */

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

/* Update FolderInfo Permit Expiration Date and Construction Start Deadline 
   where applicable. */

   EXECUTE dbo.usp_Zoning_Permit_Expiration_Dates @FolderRSN, @DecisionDate

/* Stop Appeal Findings clock. Stop the Scheduler clock if it is still running. 
   It is supposed to stop when a DRB Meeting Date is entered (Info), but the date 
   might not have been entered. */

IF @AppealFindingsClock > 0
BEGIN
   UPDATE FolderClock
      SET FolderClock.Status = 'Stopped'
    WHERE FolderClock.FolderRSN = @FolderRSN
      AND FolderClock.FolderClock = 'Appeal Fdngs'
END

IF @SchedulerClock > 0 AND @SchedulerClockStatus = 'Running'
BEGIN
   SELECT @InitiateAppealAttemptResult = dbo.udf_GetProcessAttemptCode(@FolderRSN, 10008)

   IF @InitiateAppealAttemptResult = 10015
      SELECT @SchedulerClockStartDate = dbo.udf_GetProcessAttemptDate(@FolderRSN, 10008)
   ELSE 
      SELECT @SchedulerClockStartDate = @InDate   /* For ZL folders */

   SELECT @SchedulerClockDayDiff = DATEDIFF(day, @SchedulerClockStartDate, @DecisionDate)

   UPDATE FolderClock
      SET FolderClock.Status = 'Stopped', 
          FolderClock.Counter = @SchedulerClockDayDiff, 
          FolderClock.StartDate= @DecisionDate 
    WHERE FolderClock.FolderRSN = @FolderRSN
      AND FolderClock.FolderClock = 'Scheduler'
END

/* Record gross review time in Appeal to DRB process. 
   Reopen Initiate Appeal (10008) process, close Review Path (10000) and Appeal Clock 
   (10018) processes. */

UPDATE FolderProcess
   SET FolderProcess.Startdate = @InDate,
       FolderProcess.EndDate = @DecisionDate
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessRSN = @ProcessRSN

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 1, FolderProcess.StartDate = NULL, 
       FolderProcess.EndDate = NULL, FolderProcess.ScheduleDate = NULL, 
       FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL, 
       FolderProcess.ProcessComment = NULL
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10008       /* Initiate Appeal */

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 2
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10000        /* Review Path */
   AND FolderProcess.StatusCode = 1

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 2
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10015        /* Review Submission - Discontinued */
   AND FolderProcess.StatusCode = 1

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 2
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10018       /* Appeal Clock */
   AND FolderProcess.StatusCode = 1



GO
