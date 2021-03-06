USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QZ_00020050]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QZ_00020050]
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
/* Initiate Appeal (20050) version 2 */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @SubCode int
DECLARE @NextSubCode int
DECLARE @WorkCode int
DECLARE @NextWorkCode int

DECLARE @AppealableDecisionInfoOrder int
DECLARE @AppealableDecisionInfoValue varchar(50)
DECLARE @DRBAppealDateInfoField int
DECLARE @DRBAppealDateInfoOrder int
DECLARE @DRBAppealDateInfoValue datetime
DECLARE @VECAppealDateInfoField int
DECLARE @VECAppealDateInfoOrder int
DECLARE @VECAppealDateinfoValue datetime
DECLARE @ViolationFinality varchar(3)
DECLARE @DecisionDate datetime
DECLARE @ExpiryDate datetime

DECLARE @InvestigationProcessOrder int
DECLARE @AppealDecisionProcessOrder int
DECLARE @AppealDecisionProcess int
DECLARE @ZoningReviewProcess int
DECLARE @ReviewRequestsProcess int
DECLARE @ReviewRequestsProcessOrder int
DECLARE @ViolationProcess int
DECLARE @ViolationProcessOrder int
DECLARE @RemedyVerifyProcess int
DECLARE @RemedyVerifyProcessOrder int

DECLARE @LitigationAttemptResult int
DECLARE @DRBCListValue varchar(1)
DECLARE @AdminCListValue varchar(1)
DECLARE @ReviewBody varchar(3)

DECLARE @TotalChecklistCheck int
DECLARE @OwnerCheckListCheck int
DECLARE @ComplainantCheckListCheck int
DECLARE @OwnerCListValue varchar(1)
DECLARE @ComplainantCListValue varchar(1)
DECLARE @WhoAppealed varchar(15)

DECLARE @RemedyVerify varchar(1)
DECLARE @CloseProcesses varchar(1)
DECLARE @CloseFolder varchar(1)
DECLARE @AppealFolderResultText varchar(100)
DECLARE @AppealProcessResultText varchar(100)

/* Get Attempt Result */

SELECT @AttemptResult = ResultCode
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

/* Check for Info field existence, set Info field display orders. */

SELECT @AppealableDecisionInfoOrder = ISNULL(FolderInfo.DisplayOrder, 200)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20068

SELECT @DRBAppealDateInfoOrder  = @AppealableDecisionInfoOrder + 10
SELECT @VECAppealDateInfoOrder  = @AppealableDecisionInfoOrder + 20

SELECT @DRBAppealDateInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20065

SELECT @VECAppealDateInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20066

/* For Appeal to DRB and VEC attempt results, get checklist values, and check to make 
   sure only one checklist item is selected. */

IF @AttemptResult IN(20104, 20105)
BEGIN
   SELECT @OwnerCListValue = FolderProcessChecklist.Passed
     FROM FolderProcessChecklist
    WHERE FolderProcessChecklist.ProcessRSN = @processRSN
      AND FolderProcessChecklist.ChecklistCode = 20034

   SELECT @ComplainantCListValue = FolderProcessChecklist.Passed
     FROM FolderProcessChecklist
    WHERE FolderProcessChecklist.ProcessRSN = @processRSN
      AND FolderProcessChecklist.ChecklistCode = 20035

   IF @OwnerCListValue = 'Y'       SELECT @OwnerChecklistCheck = 1
   IF @ComplainantCListValue = 'Y' SELECT @ComplainantChecklistCheck = 1

   SELECT @TotalChecklistCheck = ISNULL(@OwnerChecklistCheck, 0) + 
                                 ISNULL(@ComplainantChecklistCheck, 0)

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

   IF @OwnerCListValue = 'Y'       SELECT @WhoAppealed = 'Owner'
   IF @ComplainantCListValue = 'Y' SELECT @WhoAppealed = 'Complainant'

   /* Get checklist values from Zoning Review process, set who hears the appeal. 
      The only way this process can be Appeal to VEC without the DRB Appeal Date 
      Info field, is appeals of DRB decisions from Zoning Review. */

   SELECT @ZoningReviewProcess = count(*)
     FROM FolderProcess
    WHERE FolderProcess.FolderRSN = @folderRSN
      AND FolderProcess.ProcessCode = 20045

   IF @ZoningReviewProcess = 0 
   BEGIN 
      SELECT @AdminCListValue = 'Y', @DRBCListValue = 'N'
   END
   ELSE
   BEGIN
      SELECT @DRBCListValue = FolderProcessChecklist.Passed
        FROM FolderProcessChecklist, FolderProcess
       WHERE FolderProcessChecklist.ProcessRSN = FolderProcess.ProcessRSN
      AND FolderProcess.ProcessCode = 20045
         AND FolderProcess.FolderRSN = @folderRSN
         AND FolderProcessChecklist.ChecklistCode = 20036

      SELECT @AdminCListValue = FolderProcessChecklist.Passed
        FROM FolderProcessChecklist, FolderProcess
       WHERE FolderProcessChecklist.ProcessRSN = FolderProcess.ProcessRSN
      AND FolderProcess.ProcessCode = 20045
         AND FolderProcess.FolderRSN = @folderRSN
         AND FolderProcessChecklist.ChecklistCode = 20037
   END

   IF @DRBAppealDateInfoField = 0 AND @AdminCListValue = 'Y' SELECT @ReviewBody = 'DRB'
   IF @DRBAppealDateInfoField = 0 AND @DRBCListValue = 'Y'   SELECT @ReviewBody = 'VEC'
   IF @DRBAppealDateInfoField > 0 SELECT @ReviewBody = 'VEC'

END      /* end of set up for AttemptResults 20104 and 20105 */

/* For No Appeal attempt result, insure the appeal period has expired. */

IF @AttemptResult = 20118 AND @WorkCode <> 20131
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('The appeal period has not expired. Choose a different attempt result, or exit this process.', 16, -1)
   RETURN
END

/* Set various process orders, and check for existence */

SELECT @InvestigationProcessOrder = ISNULL(FolderProcess.DisplayOrder, 100)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20046

SELECT @ReviewRequestsProcessOrder = @InvestigationProcessOrder + 20
SELECT @AppealDecisionProcessOrder = @InvestigationProcessOrder + 60
SELECT @ViolationProcessOrder      = @InvestigationProcessOrder + 90
SELECT @RemedyVerifyProcessOrder   = @InvestigationProcessOrder + 100

SELECT @ViolationProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 20047

SELECT @AppealDecisionProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20049

SELECT @ReviewRequestsProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 20052

SELECT @RemedyVerifyProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 20053

/* Appeal to DRB attempt result */

IF @AttemptResult = 20104
BEGIN

   IF @ReviewBody = 'VEC'
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Folder set up for an appeal to the VEC. Choose Appeal to VEC to continue.', 16, -1)
   RETURN
   END

   UPDATE Folder
      SET Folder.WorkCode = 20104, 
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Decision Appealed to ' + @ReviewBody + ' (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = @WhoAppealed + ' Appealed to ' + @ReviewBody,
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Appealed to ' + @ReviewBody, 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   IF @DRBAppealDateInfoField = 0
   BEGIN
   INSERT INTO FolderInfo
                  ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                    StampDate, StampUser, Mandatory, ValueRequired )
           VALUES ( @FolderRSN, 20065, @DRBAppealDateInfoOrder, 'Y', 
                     getdate(), @UserID, 'N', 'N' )
   END

END    /* end of Appeal to DRB attempt result */

/* Appeal to VEC attempt result */

IF @AttemptResult = 20105
BEGIN

   IF @ReviewBody = 'DRB'
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Folder set up for an appeal to the DRB. Choose Appeal to DRB to continue.', 16, -1)
      RETURN
   END

   UPDATE Folder
      SET Folder.WorkCode = 20117, 
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Decision Appealed to ' + @ReviewBody + ' (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = @WhoAppealed + ' Appealed to ' + @ReviewBody,
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessRSN = @processRSN

 UPDATE FolderProcessAttempt
   SET FolderProcessAttempt.AttemptComment = 'Appealed to ' + @ReviewBody, 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   IF @VECAppealDateInfoField = 0
   BEGIN
   INSERT INTO FolderInfo
                  ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                    StampDate, StampUser, Mandatory, ValueRequired )
           VALUES ( @FolderRSN, 20066, @VECAppealDateInfoOrder, 'Y', 
                     getdate(), @UserID, 'N', 'N' )
   END

END    /* end of Appeal to VEC attempt result */

/* No Appeal attempt result */

IF @AttemptResult = 20118
BEGIN
   SELECT @AppealableDecisionInfoValue = FolderInfo.InfoValue
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = 20068

   SELECT @NextSubCode =
   CASE @AppealableDecisionInfoValue
      WHEN 'Grandfathering - Denied' THEN 20065
      WHEN 'Grandfathering - Approved' THEN 20061
      WHEN 'Functional Family - Denied' THEN 20065
      WHEN 'Functional Family - Approved' THEN 20062
      WHEN 'Zoning Review - Denied' THEN 20065
      WHEN 'Zoning Review - Approved' THEN 20063
      WHEN 'Investigation - Complaint Unfounded' THEN 20064
      WHEN 'Investigation - Notice of Violation' THEN 20065
   END

   SELECT @ViolationFinality =
   CASE @AppealableDecisionInfoValue
      WHEN 'Grandfathering - Denied' THEN 'Yes'
      WHEN 'Grandfathering - Approved' THEN 'No'
      WHEN 'Functional Family - Denied' THEN 'Yes'
      WHEN 'Functional Family - Approved' THEN 'No'
      WHEN 'Zoning Review - Denied' THEN 'Yes'
      WHEN 'Zoning Review - Approved' THEN 'No'
      WHEN 'Investigation - Complaint Unfounded' THEN 'No'
      WHEN 'Investigation - Notice of Violation' THEN 'Yes'
   ELSE 'No'
   END

   SELECT @NextWorkCode =
   CASE @AppealableDecisionInfoValue
      WHEN 'Grandfathering - Denied' THEN 20112
      WHEN 'Grandfathering - Approved' THEN 20129
      WHEN 'Functional Family - Denied' THEN 20112
      WHEN 'Functional Family - Approved' THEN 20129
      WHEN 'Zoning Review - Denied' THEN 20112
      WHEN 'Zoning Review - Approved' THEN 20129
      WHEN 'Investigation - Complaint Unfounded' THEN 20110
      WHEN 'Investigation - Notice of Violation' THEN 20112
   END

   SELECT @RemedyVerify =
   CASE @AppealableDecisionInfoValue
      WHEN 'Grandfathering - Denied' THEN 'N'
      WHEN 'Grandfathering - Approved' THEN 'Y'
      WHEN 'Functional Family - Denied' THEN 'N'
      WHEN 'Functional Family - Approved' THEN 'Y'
      WHEN 'Zoning Review-Denied' THEN 'N'
      WHEN 'Zoning Review - Approved' THEN 'Y'
      WHEN 'Investigation - Complaint Unfounded' THEN 'N'
      WHEN 'Investigation - Notice of Violation' THEN 'N'
      WHEN 'None' THEN 'N'
      ELSE 'N'
   END

   SELECT @CloseProcesses =
   CASE @AppealableDecisionInfoValue
      WHEN 'Grandfathering - Denied' THEN 'V'
      WHEN 'Grandfathering - Approved' THEN 'Y'
      WHEN 'Functional Family - Denied' THEN 'V'
      WHEN 'Functional Family - Approved' THEN 'Y'
      WHEN 'Zoning Review - Denied' THEN 'V'
      WHEN 'Zoning Review - Approved' THEN 'Y'
      WHEN 'Investigation - Complaint Unfounded' THEN 'Y'
      WHEN 'Investigation - Notice of Violation' THEN 'V'
      WHEN 'None' THEN 'N'
      ELSE 'N'
   END

   SELECT @CloseFolder =
   CASE @AppealableDecisionInfoValue
      WHEN 'Grandfathering - Denied' THEN 'N'
      WHEN 'Grandfathering - Approved' THEN 'N'
      WHEN 'Functional Family - Denied' THEN 'N'
      WHEN 'Functional Family - Approved' THEN 'N'
      WHEN 'Zoning Review - Denied' THEN 'N'
      WHEN 'Zoning Review - Approved' THEN 'N'
      WHEN 'Investigation - Complaint Unfounded' THEN 'Y'
      WHEN 'Investigation - Notice of Violation' THEN 'N'
      WHEN 'None' THEN 'N'
      ELSE 'N'
   END

   SELECT @AppealFolderResultText =
   CASE @AppealableDecisionInfoValue
      WHEN 'Grandfathering - Denied' THEN 'Appeal Period Expired -> Grandfathering is Denied -> Violation Finality'
      WHEN 'Grandfathering - Approved' THEN 'Appeal Period Expired -> Grandfathering is Approved'
      WHEN 'Functional Family - Denied' THEN 'Appeal Period Expired -> Functional Family is Denied -> Violation Finality'
      WHEN 'Functional Family - Approved' THEN 'Appeal Period Expired -> Functional Family is Approved'
      WHEN 'Zoning Review - Denied' THEN 'Appeal Period Expired -> Zoning Request is Denied -> Violation Finality'
      WHEN 'Zoning Review - Approved' THEN 'Appeal Period Expired -> Zoning Request is Approved'
      WHEN 'Investigation - Complaint Unfounded' THEN 'Appeal Period Expired -> Complaint is Unfounded -> Complaint Resolved'
      WHEN 'Investigation - Notice of Violation' THEN 'Appeal Period Expired -> Violation has Finality'
      WHEN 'None' THEN ' '
      ELSE ' '
   END

   SELECT @AppealProcessResultText =
   CASE @AppealableDecisionInfoValue
      WHEN 'Grandfathering - Denied' THEN 'No Appeal of Grandfathering Decision (Denied)'
      WHEN 'Grandfathering - Approved' THEN 'No Appeal of Grandfathering Decision (Approved)'
      WHEN 'Functional Family - Denied' THEN 'No Appeal of Functional Family Decision (Denied)'
      WHEN 'Functional Family - Approved' THEN 'No Appeal of Functional Family Decision (Approved)'
      WHEN 'Zoning Review - Denied' THEN 'No Appeal of Zoning Decision (Denied)'
      WHEN 'Zoning Review - Approved' THEN 'No Appeal of Zoning Decision (Approved)'
      WHEN 'Investigation - Complaint Unfounded' THEN 'No Appeal of Complaint Unfounded Decision'
      WHEN 'Investigation - Notice of Violation' THEN 'No Appeal of Notice of Violation'
      WHEN 'None' THEN ' '
      ELSE ' '
   END

   SELECT @LitigationAttemptResult = count(*)
     FROM FolderProcessAttempt, FolderProcess
    WHERE FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
      AND FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessCode = 20047
      AND FolderProcessAttempt.ResultCode = 20098

   IF @LitigationAttemptResult > 0 
   BEGIN
      SELECT @NextSubCode = 20065, @NextWorkCode = 20128
      SELECT @AppealFolderResultText = 'Litigation Appeal Period Expired'
      SELECT @RemedyVerify = 'Y', @CloseProcesses = 'Y'
   END

   UPDATE Folder
      SET Folder.SubCode = @NextSubCode, Folder.WorkCode = @NextWorkCode, 
          Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> ' + @AppealFolderResultText + ' (' + CONVERT(CHAR(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = @AppealProcessResultText,
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = @AppealProcessResultText, 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   IF @ViolationFinality = 'Yes'
   BEGIN
      UPDATE FolderInfo
         SET FolderInfo.InfoValue = 'Yes', FolderInfo.InfoValueUpper = 'YES'
       WHERE FolderInfo.FolderRSN = @FolderRSN
         AND FolderInfo.InfoCode = 20071
   END

   IF @RemedyVerify = 'Y'
   BEGIN
      IF @RemedyVerifyProcess = 0
 BEGIN 
         SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
           FROM FolderProcess

         INSERT INTO FolderProcess
                   ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
                     ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
                     DisplayOrder, PrintFlag, MandatoryFlag, StampDate )
            VALUES ( @NextProcessRSN, @FolderRSN, 20053, 80, 1,
                     getdate(), (getdate() + 180), getdate(), (getdate() + 180), 
                     @RemedyVerifyProcessOrder, 'Y', 'Y', getdate() )
      END

      IF @RemedyVerifyProcess > 0
      BEGIN
         UPDATE FolderProcess
            SET FolderProcess.StatusCode = 1, EndDate = NULL
          WHERE FolderProcess.ProcessCode = 20053
           AND FolderProcess.FolderRSN = @FolderRSN
      END
   END

   IF @CloseProcesses = 'Y'
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 2, 
             FolderProcess.EndDate = getdate(), FolderProcess.BaseLineEndDate = getdate()
       WHERE FolderProcess.StatusCode = 1
         AND FolderProcess.ProcessCode IN(20042, 20043, 20044, 20045, 20046, 20047, 
                                          20049, 20051, 20052)
         AND FolderProcess.FolderRSN = @FolderRSN
   END

   IF @CloseProcesses = 'V'
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 2, 
             FolderProcess.EndDate = getdate(), FolderProcess.BaseLineEndDate = getdate()
       WHERE FolderProcess.StatusCode = 1
         AND FolderProcess.ProcessCode IN(20042, 20043, 20044, 20045, 20046, 20052)
         AND FolderProcess.FolderRSN = @FolderRSN

      /* If Review Requests is to be added or opened, un-comment below and delete 
         20052 above.

      IF @ReviewRequestsProcess = 0
      BEGIN 
         SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
           FROM FolderProcess

         INSERT INTO FolderProcess
                   ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
                     ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
                     DisplayOrder, PrintFlag, MandatoryFlag, StampDate )
            VALUES ( @NextProcessRSN, @FolderRSN, 20052, 80, 1,
                 getdate(), (getdate() + 180), getdate(), (getdate() +180), 
                     @ReviewRequestsProcessOrder, 'Y', 'Y', getdate() )
      END

      IF @ReviewRequestsProcess > 0
      BEGIN
         UPDATE FolderProcess
                SET FolderProcess.StatusCode = 1, EndDate = NULL
          WHERE FolderProcess.ProcessCode = 20052
               AND FolderProcess.FolderRSN = @FolderRSN
      END  */

      IF @ViolationProcess = 0
      BEGIN 
         SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
           FROM FolderProcess

         INSERT INTO FolderProcess
                   ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
                     ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
                     DisplayOrder, PrintFlag, MandatoryFlag, StampDate )
            VALUES ( @NextProcessRSN, @FolderRSN, 20047, 80, 1,
                     getdate(), (getdate() + 180), getdate(), (getdate() + 180), 
                     @ViolationProcessOrder, 'Y', 'Y', getdate() )
      END

      IF @ViolationProcess > 0
      BEGIN
         UPDATE FolderProcess
            SET FolderProcess.StatusCode = 1, EndDate = NULL
          WHERE FolderProcess.ProcessCode = 20047
            AND FolderProcess.FolderRSN = @FolderRSN
      END

   END

END    /* end of No Appeal attempt result */


/* Process closes; close SC Memo Response and Investigation processes. 
   Add or re-open Appeal Decision process. */

IF @AttemptResult IN(20104, 20105)
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 2, 
          FolderProcess.EndDate = getdate(), 
     FolderProcess.BaseLineEndDate = getdate(), 
          FolderProcess.SignOffUser = @UserID
    WHERE FolderProcess.StatusCode = 1
      AND FolderProcess.ProcessCode IN(20042, 20043, 20044, 20045, 20046, 20047, 
                            20050, 20051, 20052, 20053)
      AND FolderProcess.FolderRSN = @folderRSN

   IF @AppealDecisionProcess = 0
   BEGIN
      SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

      INSERT INTO FolderProcess
             ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
               ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
               AssignedUser, DisplayOrder,
               PrintFlag, MandatoryFlag, StampDate, StampUser )
      VALUES ( @NextProcessRSN, @folderRSN, 20049, 80, 1,
               getdate(), (getdate() + 180), getdate(), (getdate() + 180), 
               @UserID, @AppealDecisionProcessOrder, 
               'Y', 'Y', getdate(), @UserID )
   END

   IF @AppealDecisionProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 20049
         AND FolderProcess.FolderRSN = @folderRSN
   END
END

IF @AttemptResult = 20118
BEGIN
   UPDATE FolderProcess                                  /* Close Initiate Appeal */
      SET FolderProcess.StatusCode = 2, 
          FolderProcess.EndDate = getdate(), FolderProcess.BaseLineEndDate = getdate()
    WHERE FolderProcess.StatusCode = 1
      AND FolderProcess.ProcessCode = 20050
      AND FolderProcess.FolderRSN = @FolderRSN

   IF @CloseFolder = 'Y'
   BEGIN
      UPDATE Folder
         SET Folder.StatusCode = 2, Folder.FinalDate = getdate()
       WHERE Folder.FolderRSN = @FolderRSN
   END
END

GO
