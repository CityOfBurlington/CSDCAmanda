USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010008]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010008]
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
/* Initiate Appeal (10008) version 6 */

/* For appeals of Primary Decisions only. Future: Use Checklist items to add 
   functionality for appeals of Secondary Decisions. */
 
DECLARE @AttemptResult int
DECLARE @AttemptDate datetime
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @ZPNumber varchar(10)

DECLARE @AppealBody varchar(10) 
DECLARE @AppealDRBProcess int
DECLARE @AppealVECProcess int
DECLARE @AppealVTSupremeProcess int
DECLARE @AppealClockProcess int
DECLARE @AppealtoDRBProcessRSN int

DECLARE @AppealFdngsClock int
DECLARE @SchedulerClock int
 
DECLARE @DRBAppealFee float
DECLARE @FilingFee float
 
DECLARE @ProjectFile varchar(10)
DECLARE @ProjectFileInfoField int          /* 10005 */
DECLARE @ProjectFileOrder int
 
/* Get attempt result, and various Folder.values */
 
SELECT @AttemptResult = FolderProcessAttempt.ResultCode, 
       @AttemptDate = FolderProcessAttempt.AttemptDate
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       (SELECT max(FolderProcessAttempt.AttemptRSN) 
          FROM FolderProcessAttempt
         WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)
 
SELECT @FolderType = Folder.FolderType, 
       @FolderStatus = Folder.StatusCode, 
       @ZPNumber = Folder.ReferenceFile, 
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN
 
/* Check for existence of Appeal to DRB, Appeal to VSCED, Appeal to SC, and 
   Appeal Clock processes. */

SELECT @AppealDRBProcess = dbo.udf_CountProcesses(@FolderRSN, 10002)
SELECT @AppealVECProcess = dbo.udf_CountProcesses(@FolderRSN, 10003)
SELECT @AppealVTSupremeProcess = dbo.udf_CountProcesses(@FolderRSN, 10029)
SELECT @AppealClockProcess = dbo.udf_CountProcesses(@FolderRSN, 10018)

/* Check for existence of Appeal Fdngs and Scheduler FolderClocks. */

SELECT @AppealFdngsClock = COUNT(*)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Appeal Fdngs'

SELECT @SchedulerClock = COUNT(*)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Scheduler'

/* Get DRB Appeal fee values. */
 
SELECT @DRBAppealFee = ValidLookup.LookupFee    /* Fee for Appeal to DRB */
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 13 
   AND ValidLookup.Lookup1 = 1 
  
SELECT @FilingFee = ValidLookup.LookupFee      /* Clerk's Filing Fee */
  FROM ValidLookup 
 WHERE ValidLookup.LookupCode = 3 
   AND ValidLookup.Lookup1 = 2 

/* Perform checks for which body will hear the appeal. These are the only validity 
checks. Whther or not a folder is in its appeal period is controlled by whether or 
not the Initiate Appeal process is open (no Folder Status checks). */

SELECT @AppealBody = dbo.udf_ZoningAppealBodyFlag(@FolderRSN) 

IF @AttemptResult = 10015 AND @AppealBody IN ('VEC', 'VSC', 'USSC')
BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('DRB is ineligible to hear this appeal. Please exit and try again.', 16, -1)
      RETURN
END

IF @AttemptResult = 10016 AND @AppealBody IN ('DRB', 'VSC', 'USSC')
BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('VT Environmental Court is ineligible to hear this appeal. Please exit and try again.', 16, -1)
      RETURN
END

IF @AttemptResult = 10064 AND @AppealBody IN ('DRB', 'VEC', 'USSC')
BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('VT Supreme Court is ineligible to hear this appeal. Please exit and try again.', 16, -1)
      RETURN
END

IF @AttemptResult = 10065 AND @AppealBody IN ('DRB', 'VEC', 'VSC')
BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('US Supreme Court is ineligible to hear this appeal. Please exit and try again.', 16, -1)
      RETURN
END
 
/* Administrative decision appealed to DRB. Check to make sure this is the correct 
   choice. Folder Status 10022 is Appeal Period - Revoked.  Permit Revocation is done 
   administratively, so appeals of that go to DRB, but this functionality is not 
   included in order to keep the programming straightforward and consistent. */
 
IF @AttemptResult = 10015              /* DRB Appeal */
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = 10009, 
          Folder.FolderCondition =  convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Appeal Received: Administrative Decision to DRB (' + CONVERT(CHAR(11), @AttemptDate) + ')' ))
    WHERE Folder.FolderRSN = @FolderRSN
 
   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Appealed to DRB'
    WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessRSN = @ProcessRSN 

   IF @SchedulerClock = 0
   BEGIN 
      INSERT INTO FolderClock  
         (FolderRSN, FolderClock, MaxCounter, StartDate, Counter, Status, Colour)
      VALUES 
         (@FolderRSN, 'Scheduler', 60, getdate(), 0, 'Running', 'Yellow')
   END
   ELSE
   BEGIN
      UPDATE FolderClock
         SET FolderClock.MaxCounter = 60, FolderClock.Startdate = getdate(), 
             FolderClock.Counter = 0, FolderClock.Status = 'Running'
       WHERE FolderClock.FolderClock = 'Scheduler' 
         AND FolderClock.FolderRSN = @FolderRSN
   END

   IF @AppealFdngsClock = 0
   BEGIN 
      INSERT INTO FolderClock  
         (FolderRSN, FolderClock, MaxCounter, StartDate, Counter, Status, Colour)
      VALUES 
         (@FolderRSN, 'Appeal Fdngs', 45, getdate(), 0, 'Not Started', 'Red')
   END
   ELSE
   BEGIN
      UPDATE FolderClock
         SET FolderClock.MaxCounter = 45, FolderClock.Startdate = getdate(), 
             FolderClock.Counter = 0, FolderClock.Status = 'Not Started'
       WHERE FolderClock.FolderClock = 'Appeal Fdngs' 
         AND FolderClock.FolderRSN = @FolderRSN
   END

   /* Insert, if necessary, and code Project File Info field */

   IF @ProjectFileInfoField > 0
   BEGIN
      SELECT @ProjectFile = UPPER(FolderInfo.InfoValue)
        FROM FolderInfo
       WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 10005
 
      IF @ProjectFile IN(NULL, 'YES', 'NO')
      BEGIN
         UPDATE FolderInfo
            SET FolderInfo.InfoValue = @ZPNumber, 
                FolderInfo.InfoValueUpper = UPPER(@ZPNumber)
          WHERE FolderInfo.InfoCode = 10005
            AND FolderInfo.FolderRSN = @folderRSN
      END
   END
 
   IF @ProjectFileInfoField = 0
   BEGIN
      SELECT @ProjectFileOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@FolderRSN, 10005) 
 
     INSERT INTO FolderInfo
                  ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                    InfoValue, InfoValueUpper, 
                    StampDate, StampUser, Mandatory, ValueRequired )
           VALUES ( @FolderRSN, 10005,  @ProjectFileOrder, 'Y', 
                    @ZPNumber, UPPER(@ZPNumber), 
                    getdate(), @UserID, 'N', 'N' )
   END

   /* Insert DRB-related Info fields where needed. */

   /* DRB Meeting Date */
   EXECUTE dbo.usp_Zoning_Insert_FolderInfo @FolderRSN, 10001, @UserID 

   /* DRB Public Hearing Closed Date */
   EXECUTE dbo.usp_Zoning_Insert_FolderInfo @FolderRSN, 10009, @UserID 

   /* DRB Deliberative Meeting Date */
   EXECUTE dbo.usp_Zoning_Insert_FolderInfo @FolderRSN, 10017, @UserID 

   /* DRB Appeal Decision Date */
   EXECUTE dbo.usp_Zoning_Insert_FolderInfo @FolderRSN, 10056, @UserID 

   IF @AppealDRBProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, FolderProcess.StartDate = NULL, 
             FolderProcess.EndDate = NULL, FolderProcess.ScheduleDate = getdate(), 
             FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL, 
             FolderProcess.ProcessComment = NULL
       WHERE FolderProcess.FolderRSN = @FolderRSN
         AND FolderProcess.ProcessCode = 10002
         AND FolderProcess.StatusCode = 2
   END

   /* Set Appeal to DRB ProcessInfo Waive Right to Appeal Option field to 'No'.  
      Default FolderProcessInfo values are not enabled in v.4.4. */

   SELECT @AppealtoDRBProcessRSN = dbo.udf_GetProcessRSN(@FolderRSN, 10002)

   UPDATE FolderProcessInfo
      SET FolderProcessInfo.InfoValue = 'No', FolderProcessInfo.InfoValueUpper = 'NO'
    WHERE FolderProcessInfo.ProcessRSN = @AppealtoDRBProcessRSN
      AND FolderProcessInfo.InfoCode = 10002
 
   /* Insert Appeal to DRB Fee */
 
   SELECT @NextRSN = @NextRSN + 1 
   INSERT INTO AccountBillFee 
             ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
               FeeAmount, 
               BillNumber, BillItemSequence, StampDate, StampUser ) 
   VALUES ( @NextRSN, @FolderRSN, 137, 'Y', 
            @DRBAppealFee, 0, 0, getdate(), @UserId )
 
   SELECT @NextRSN = @NextRSN + 1 
   INSERT INTO AccountBillFee 
             ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
               FeeAmount, 
               BillNumber, BillItemSequence, StampDate, StampUser ) 
   VALUES ( @NextRSN, @FolderRSN, 81, 'Y', 
            @FilingFee, 0, 0, getdate(), @UserId )
 
END        /* End of Attempt Result 10015 */
 
/* DRB decision appealed to Vermont Superior Court Environmental Division (VEC). 
   Check to make sure this is the correct choice. 
   Note: Consider setting VEC paperwork checklist start and end dates */ 
 
IF @AttemptResult = 10016             /* VSCED Appeal */
BEGIN 
   UPDATE Folder
      SET Folder.StatusCode = 10017, 
          Folder.FolderCondition =   convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Appeal Received: DRB Decision to Environmental Court (' + CONVERT(CHAR(11), @AttemptDate) + ')' ))
    WHERE Folder.FolderRSN = @FolderRSN
 
   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Appealed to VSCED'
    WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessRSN = @ProcessRSN 
 
    /* VEC Appeal Date */
   EXECUTE dbo.usp_Zoning_Insert_FolderInfo @FolderRSN, 10038, @UserID 

   /* VEC Appeal Docket Number */
   EXECUTE dbo.usp_Zoning_Insert_FolderInfo @FolderRSN, 10069, @UserID 

   /* VEC Appeal Decision Date */
   EXECUTE dbo.usp_Zoning_Insert_FolderInfo @FolderRSN, 10057, @UserID  

   UPDATE FolderInfo
      SET FolderInfo.InfoValue = CONVERT(CHAR(11), getdate()), 
          FolderInfo.InfoValueDatetime = getdate()
    WHERE FolderInfo.FolderRSN = @FolderRSN 
      AND FolderInfo.InfoCode = 10038

   IF @AppealVECProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, FolderProcess.StartDate = NULL, 
             FolderProcess.EndDate = NULL, FolderProcess.ScheduleDate = getdate(), 
       FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL, 
             FolderProcess.ProcessComment = NULL
       WHERE FolderProcess.FolderRSN = @FolderRSN
         AND FolderProcess.ProcessCode = 10003
        AND FolderProcess.StatusCode = 2
   END
  
END    /* End of Attempt Result 10016 */

IF @AttemptResult = 10064             /* VT Supreme Court Appeal */
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = 10036, 
          Folder.FolderCondition =   convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Appeal Received: VEC Decision to VT Supreme Court (' + CONVERT(CHAR(11), @AttemptDate) + ')' ))
    WHERE Folder.FolderRSN = @FolderRSN
 
   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Appealed to VT Supreme Court'
    WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessRSN = @ProcessRSN 
 
   /* Supreme Court Docket Number */
   EXECUTE dbo.usp_Zoning_Insert_FolderInfo @FolderRSN, 10079, @UserID 

   /* Supreme Court Appeal Decision Date */
   EXECUTE dbo.usp_Zoning_Insert_FolderInfo @FolderRSN, 10080, @UserID 

  IF @AppealVTSupremeProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, FolderProcess.StartDate = NULL, 
             FolderProcess.EndDate = NULL, FolderProcess.ScheduleDate = getdate(), 
             FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL, 
             FolderProcess.ProcessComment = NULL
       WHERE FolderProcess.FolderRSN = @FolderRSN
         AND FolderProcess.ProcessCode = 10029
         AND FolderProcess.StatusCode = 2
   END

END    /* End of Attempt Result 10064 */

IF @AttemptResult = 10065             /* US Supreme Court Appeal */
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = 10046, 
          Folder.FolderCondition =   convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Appeal Received: VSCED Decision to US Supreme Court (' + CONVERT(CHAR(11), @AttemptDate) + ')' ))
    WHERE Folder.FolderRSN = @FolderRSN
 
   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Appealed to US Supreme Court'
    WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessRSN = @ProcessRSN 

END    /* End of Attempt Result 10065 */

/* Re-open Appeal Clock, if present. It is done for Appeal to DRB only, as 
   VEC and Supreme Court appeals are beyond the City's control. */

IF ( @AppealClockProcess > 0 AND @AttemptResult = 10015 )
BEGIN
   UPDATE FolderProcess
    SET FolderProcess.StatusCode = 1, FolderProcess.StartDate = NULL, 
          FolderProcess.EndDate = NULL, FolderProcess.ScheduleDate = getdate(), 
          FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL, 
          FolderProcess.ProcessComment = NULL
    WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessCode = 10018
END 

GO
