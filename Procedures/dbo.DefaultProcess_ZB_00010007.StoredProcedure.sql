USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010007]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010007]
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
/* Review Clock (10007) version 5 */

/* Used for applicant actions that effect review clock. */

/* Functionality for appeals is in the Appeal Clock process. */

DECLARE @AttemptResult int
DECLARE @AttemptDate datetime
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @NextStatusCode int
DECLARE @InDate datetime
DECLARE @ExpiryDate datetime
DECLARE @SubCode int 
DECLARE @WorkCode int
DECLARE @FolderCondition varchar(2000)
DECLARE @RCAttemptCount int
DECLARE @RCCompleteAttemptCount int
DECLARE @ClockStatus varchar(12)
DECLARE @ClockCounter int
DECLARE @ClockStatusScheduler varchar(12)

/* Get Attempt Result, Folder Status, In Date, Appeal Period expiration date, 
   Conditions. Get FolderClock Review values. */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode, 
       @AttemptDate = FolderProcessAttempt.AttemptDate
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

SELECT @FolderType = Folder.FolderType,
       @FolderStatus = Folder.StatusCode, 
       @InDate = Folder.InDate,
       @ExpiryDate = Folder.ExpiryDate,
       @SubCode = Folder.SubCode, 
       @WorkCode = Folder.WorkCode, 
       @FolderCondition = Folder.FolderCondition
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

SELECT @ClockStatus  = ISNULL(FolderClock.Status, 'Not Started'), 
       @ClockCounter = ISNULL(FolderClock.Counter, 0)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Admin Review'

SELECT @ClockStatusScheduler  = ISNULL(FolderClock.Status, 'Not Started')
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Scheduler'

/* Count existing attempt results - used to force first attempt to be either 
   Application Complete (10005) or Application Incomplete (10019). 
   Then check for existence of the Application Complete attempt result. This must 
   be run prior to other attempt results in order to start the clock, and add the 
   Project Decision or Appeal to DRB processes. */ 

SELECT @RCAttemptCount = COUNT(*)
  FROM FolderProcessAttempt, FolderProcess
 WHERE FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
   AND FolderProcessAttempt.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10007

SELECT @RCCompleteAttemptCount = COUNT(*)
  FROM FolderProcessAttempt, FolderProcess
 WHERE FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
   AND FolderProcessAttempt.FolderRSN = @FolderRSN
   AND FolderProcessAttempt.ResultCode = 10005
   AND FolderProcess.ProcessCode = 10007

IF ( @RCAttemptCount = 1 AND @AttemptResult NOT IN(10005, 10019) )
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please select Application Complete or Application Incomplete in order to proceed.', 16, -1)
   RETURN
END

IF ( @RCCompleteAttemptCount = 0 AND @AttemptResult = 10027 )
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please designate the Application as Complete in order to proceed.', 16, -1)
   RETURN
END

/* If the Folder.FolderCondition is null, i.e. Review Path has not been run, record when 
   the application was accepted. */

IF @FolderCondition IS NULL
BEGIN
   UPDATE Folder
      SET Folder.FolderCondition = 'Application Received ('+ CONVERT(char(11), @InDate) + ')'
    WHERE Folder.FolderRSN = @folderRSN
END

/* Initial review of application determines application is complete - clock starts. 
   The Admin Review clock counter is started at 1 to take into account that this 
   attempt result is generally immediately followed by an attempt result that stops 
   it. */

IF @AttemptResult = 10005                /* Application Complete */
BEGIN
   IF @FolderStatus IN (10000, 10014, 10015, 10019)  /* App Accepted, App Incomplete, Review Postponed, Review Waiting */
 BEGIN  
      SELECT @NextStatusCode = 10001

      UPDATE Folder
         SET Folder.StatusCode = @NextStatusCode, 
             Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> Complete Application (' + CONVERT(CHAR(11), @AttemptDate) + ')' ))
       WHERE Folder.FolderRSN = @FolderRSN

      UPDATE FolderProcess
         SET FolderProcess.ProcessComment = 'Application is Complete'
       WHERE FolderProcess.FolderRSN = @FolderRSN
         AND FolderProcess.ProcessRSN = @ProcessRSN

      UPDATE FolderClock
         SET FolderClock.Status = 'Running', 
             FolderClock.Counter = 1, 
             FolderClock.StartDate = getdate()
       WHERE FolderClock.FolderRSN = @FolderRSN
         AND FolderClock.FolderClock = 'Admin Review'
   END

END     /* End of Attempt Result 10005 */

/* Initial review of application determines there is not enough info to continue 
   review - Application Incomplete. */

IF @AttemptResult = 10019                /* Application Incomplete */
BEGIN
   IF @FolderStatus = 10000              /* App Accepted */
   BEGIN
      UPDATE Folder
         SET Folder.StatusCode = 10014, 
             Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> Incomplete Application (' + CONVERT(CHAR(11), @AttemptDate) + ')' ))
       WHERE Folder.FolderRSN = @FolderRSN

      UPDATE FolderProcess
         SET FolderProcess.ProcessComment = 'Application is Incomplete'
       WHERE FolderProcess.FolderRSN = @FolderRSN
         AND FolderProcess.ProcessRSN = @ProcessRSN
   END

END     /* End of Attempt Result 10019 */

/* Applicant will not provide sufficient information to process permit application. 
   Sets Folder.StatusCode to In Review so Porject Decision (10005) is added. 
   User then Review Path to setup for Administrative  Review and Denies the request. */

IF @AttemptResult = 10051                /* Deny Incomplete Application */
BEGIN
   IF @FolderStatus IN (10014, 10015, 10019)  /* App Incomplete, Review Postponed, Review Waiting */
   BEGIN  
      SELECT @NextStatusCode = 10001          /* Adds Project Decision */

      UPDATE Folder
         SET Folder.StatusCode = @NextStatusCode, 
             Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> Move to Deny Incomplete Application (' + CONVERT(CHAR(11), @AttemptDate) + ')' ))
       WHERE Folder.FolderRSN = @FolderRSN

      UPDATE FolderProcess
         SET FolderProcess.ProcessComment = 'Move to Deny Incomplete Application'
       WHERE FolderProcess.FolderRSN = @FolderRSN
         AND FolderProcess.ProcessRSN = @ProcessRSN

      UPDATE FolderClock
         SET FolderClock.Status = 'Running', 
             FolderClock.Counter = 1, 
             FolderClock.StartDate = getdate()
       WHERE FolderClock.FolderRSN = @FolderRSN
         AND FolderClock.FolderClock = 'Admin Review'
   END

END     /* End of Attempt Result 10051 */

/* Application was previously deemed Complete, but staff has now requested additional 
   information from the applicant. */

IF @AttemptResult = 10031             /* Waiting for Applicant Info */
BEGIN
   IF @FolderStatus IN(10001, 10015)  /* In Review, Review Postponed */
   BEGIN
      UPDATE Folder
         SET Folder.StatusCode = 10019, 
             Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> Waiting for More Info from Applicant (' + CONVERT(CHAR(11), @AttemptDate) + ')' ))
       WHERE Folder.FolderRSN = @FolderRSN

      UPDATE FolderProcess
         SET FolderProcess.ProcessComment = 'More Info Requested for Review'
       WHERE FolderProcess.FolderRSN = @FolderRSN
         AND FolderProcess.ProcessRSN = @ProcessRSN 

      IF @ClockStatus = 'Running'
      BEGIN
         UPDATE FolderClock
       SET FolderClock.Status = 'Paused' 
          WHERE FolderClock.FolderRSN = @FolderRSN
            AND FolderClock.FolderClock = 'Admin Review'
      END

      IF @ClockStatusScheduler = 'Running' AND @WorkCode = 10003
      BEGIN
         UPDATE FolderClock
            SET FolderClock.Status = 'Paused' 
          WHERE FolderClock.FolderRSN = @FolderRSN
            AND FolderClock.FolderClock = 'Scheduler'
      END
   END

END     /* End of Attempt Result 10031 */

/* Applicant postpones review, and stops clock. */

IF @AttemptResult = 10026             /* Postpone Request */
BEGIN
   IF @FolderStatus IN(10001, 10014, 10019) /* In Review, Incomplete App, Review Waiting */
   BEGIN
      UPDATE Folder
         SET Folder.StatusCode = 10015, 
             Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> Applicant Postponed Review (' + CONVERT(CHAR(11), @AttemptDate) + ')' ))
       WHERE Folder.FolderRSN = @FolderRSN

     UPDATE FolderProcess
         SET FolderProcess.ProcessComment = 'Postponed Review'
       WHERE FolderProcess.FolderRSN = @FolderRSN
         AND FolderProcess.ProcessRSN = @ProcessRSN 

      IF @ClockStatus = 'Running'
      BEGIN
         UPDATE FolderClock
            SET FolderClock.Status = 'Paused' 
          WHERE FolderClock.FolderRSN = @FolderRSN
            AND FolderClock.FolderClock = 'Admin Review'
      END
      IF @ClockStatusScheduler = 'Running' AND @WorkCode = 10003
      BEGIN
         UPDATE FolderClock
            SET FolderClock.Status = 'Paused' 
          WHERE FolderClock.FolderRSN = @FolderRSN
            AND FolderClock.FolderClock = 'Scheduler'
      END
   END

END     /* End of Attempt Result 10026 */

/* Applicant is ready or supplies requested info, and restarts the review clock. */

IF @AttemptResult = 10027                    /* Restart Clock */
BEGIN
   IF @FolderStatus IN(10014, 10015, 10019)  /* Incomplete App, Review Postponed, Review Waiting */
   BEGIN
      UPDATE Folder
         SET Folder.StatusCode = 10001, 
             Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> Applicant Restarted Review (' + CONVERT(char(11), @AttemptDate) + ')' ))
       WHERE Folder.FolderRSN = @FolderRSN

      UPDATE FolderProcess
         SET FolderProcess.ProcessComment = 'Restarted Review'
       WHERE FolderProcess.FolderRSN = @FolderRSN
         AND FolderProcess.ProcessRSN = @ProcessRSN 

      IF @ClockStatus = 'Paused'
      BEGIN
         UPDATE FolderClock
            SET FolderClock.Status = 'Running', 
                FolderClock.StartDate = getdate() 
          WHERE FolderClock.FolderRSN = @FolderRSN
            AND FolderClock.FolderClock = 'Admin Review'
      END

      IF @ClockStatusScheduler = 'Paused' AND @WorkCode = 10003
      BEGIN
         UPDATE FolderClock
   SET FolderClock.Status = 'Running', 
                FolderClock.StartDate = getdate() 
          WHERE FolderClock.FolderRSN = @FolderRSN
            AND FolderClock.FolderClock = 'Scheduler'
      END
   END

END     /* End of Attempt Result 10027 */

/* Applicant withdraws application, which can be done at any Status, including 
   Ready to Release (but not including appeal statuses). 
   Like Project Decision, record total gross review time in process start and end 
   dates in Review Path. Set status to Withdrawn and close all processes. */

IF @AttemptResult = 10035            /* Withdraw Application */
BEGIN

   IF @FolderStatus IN(10000, 10001, 10002, 10003, 10004, 10005, 10014, 10015, 10016, 10018, 10019, 10027)
   BEGIN
     UPDATE Folder
        SET Folder.StatusCode = 10010, 
            Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> Application Withdrawn (' + CONVERT(CHAR(11), @AttemptDate) + ')' ))
      WHERE Folder.FolderRSN = @FolderRSN

     UPDATE FolderClock
        SET FolderClock.Status = 'Stopped'
      WHERE FolderClock.FolderRSN = @FolderRSN
        AND FolderClock.FolderClock = 'Admin Review'

     UPDATE FolderClock
        SET FolderClock.Status = 'Stopped'
      WHERE FolderClock.FolderRSN = @FolderRSN
        AND FolderClock.FolderClock = 'Scheduler'
  
     UPDATE FolderProcess
        SET FolderProcess.ProcessComment = 'Application Withdrawn'
      WHERE FolderProcess.FolderRSN = @FolderRSN
        AND FolderProcess.ProcessRSN = @ProcessRSN 

      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate(), 
             FolderProcess.ScheduleDate = null
       WHERE FolderProcess.FolderRSN = @FolderRSN
         AND FolderProcess.StatusCode = 1

      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 2, FolderProcess.StartDate = @InDate, 
             FolderProcess.EndDate = getdate()
       WHERE FolderProcess.FolderRSN = @FolderRSN
         AND FolderProcess.ProcessCode = 10000             /* Review Path */
   END

END     /* End of Attempt Result 10035 */

/* Update Project Manager Info field. */

IF @attemptResult IN (10005, 10019, 10035, 10051) 
   EXECUTE dbo.usp_Zoning_Update_Project_Manager @FolderRSN, @UserID

/* Re-open process for all attempt results except Withdraw Application (10035) and 
   Withdraw Appeal (10004) */

IF @AttemptResult <> 10035
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
