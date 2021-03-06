USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010000]    Script Date: 9/9/2013 9:56:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010000]
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

/* Review Path (10000) version 7 */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(4)
DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @ZPNumber varchar(20)
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @FolderConditions varchar(2000)
DECLARE @ProjectFile varchar(10)
DECLARE @ParentRSN int
DECLARE @ParentZPNumber varchar(10)
DECLARE @ProjDecRSN int
DECLARE @AppealtoDRBProcessRSN int
DECLARE @UserName varchar(30)
DECLARE @AppealText varchar(50)
DECLARE @RCAttemptCount int
DECLARE @RCLastAttemptCode int
DECLARE @PublicHearingRequired varchar(2)
DECLARE @WaiveAppealProcessInfoCountProject int
DECLARE @WaiveAppealProcessInfoCountAppeal int
DECLARE @varProcessComment varchar(50)

DECLARE @AdminOrder int
DECLARE @AdminInfoField int
DECLARE @AdminInfoValue datetime
DECLARE @AdminChecklistPass varchar(1)
DECLARE @AdminNote varchar(10)

DECLARE @DABOrder int
DECLARE @DABInfoField int
DECLARE @DABInfoValue datetime
DECLARE @DABChecklistPass varchar(1)
DECLARE @DABNote varchar(10)

DECLARE @CBOrder int
DECLARE @CBInfoField int
DECLARE @CBInfoValue datetime
DECLARE @CBChecklistPass varchar(1)
DECLARE @CBNote varchar(10)

DECLARE @DRBChecklistPass varchar(1)
DECLARE @DRBNote varchar(10)

DECLARE @DABStaffCommentsDoc int
DECLARE @DABStaffCommentsGenerated datetime
DECLARE @DRBStaffCommentsDoc int
DECLARE @DRBStaffCommentsGenerated datetime

DECLARE @AdminReviewClock int
DECLARE @DRBFindingsClock int
DECLARE @AppealFindingsClock int

/* Get Attempt Result */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
   ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

/* Get Folder Type, Folder Status, Application Date, ZP Number, SubCode, WorkCode, 
   Conditions, Parent RSN, Project File InfoValue, Use name, and Project Manager 
   InfoValue. */

SELECT @FolderType = Folder.FolderType, 
       @FolderStatus = Folder.StatusCode,
       @InDate = Folder.InDate,
       @ZPNumber = Folder.ReferenceFile, 
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode,
       @FolderConditions = Folder.FolderCondition, 
       @ParentRSN = Folder.ParentRSN
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

IF @ParentRSN > 0 
BEGIN 
   SELECT @ParentZPNumber = Folder.ReferenceFile
     FROM Folder
    WHERE Folder.FolderRSN = @ParentRSN
END

SELECT @ProjectFile = FolderInfo.InfoValue
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 10005

SELECT @UserName = ValidUser.UserName
  FROM ValidUser
 WHERE ValidUser.UserID = @UserID

/* Check Review Clock. End processing if Review Clock has not been run first. 
   Appeals of Code and misc zoning decisions are excluded because the clock starts 
   running upon receipt of the appeal. There is no complete/incomplete trigger for 
   appeals in the 2008 ordinance. Get the last attempt result to enable 
   administrative denial of incomplete ZH applications. */

SELECT @RCAttemptCount = COUNT(*)
  FROM FolderProcessAttempt, FolderProcess
 WHERE FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
   AND FolderProcessAttempt.FolderRSN = @FolderRSN
   AND FolderProcessAttempt.ResultCode IN (10005, 10051)
   AND FolderProcess.ProcessCode = 10007

IF @RCAttemptCount = 0 AND @FolderType <> 'ZL' 
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('You must first use Review Clock to designate the Application as Complete in order to proceed.', 16, -1)
   RETURN
END

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

/* Check if a Public Hearing is required. 
   Set display orders for adding Info fields, and check for existence. */

SELECT @PublicHearingRequired = dbo.udf_ZoningPublicHearingFlag(@FolderRSN)

SELECT @CBOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@FolderRSN, 10007)
SELECT @CBInfoField = dbo.udf_FolderInfoFieldExists(@FolderRSN, 10007) 
SELECT @CBInfoValue = dbo.f_info_date(@FolderRSN, 10007)

SELECT @DABOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@FolderRSN, 10003)
SELECT @DABInfoField = dbo.udf_FolderInfoFieldExists(@FolderRSN, 10003) 
SELECT @DABInfoValue = dbo.f_info_date(@FolderRSN, 10003)

SELECT @AdminOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@FolderRSN, 10055)
SELECT @AdminInfoField = dbo.udf_FolderInfoFieldExists(@FolderRSN, 10055) 
SELECT @AdminInfoValue = dbo.f_info_date(@FolderRSN, 10055)

/* Determine whether Board meeting date, permit number, and decision date, 
   and the Congratulations Letter document, exist */

SELECT @DABStaffCommentsDoc = count(*)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @FolderRSN
   AND FolderDocument.DocumentCode = 10011

SELECT @DABStaffCommentsGenerated = FolderDocument.DateGenerated
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @FolderRSN
   AND FolderDocument.DocumentCode = 10011

SELECT @DRBStaffCommentsDoc = count(*)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @FolderRSN
   AND FolderDocument.DocumentCode = 10000

SELECT @DRBStaffCommentsGenerated = FolderDocument.DateGenerated
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @FolderRSN
   AND FolderDocument.DocumentCode = 10000

/* Check for existence of Folder Clocks: DRB Findings, Appeal Findings, and 
   Admin Review. */

SELECT @DRBFindingsClock = COUNT(*)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'DRB Findings'

SELECT @AppealFindingsClock = COUNT(*)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Appeal Fdngs'

SELECT @AdminReviewClock = COUNT(*)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Admin Review'

/* Determine which checklists are Yes or No in Review Path (10000) */

SELECT @AdminChecklistPass = FolderProcessChecklist.Passed
  FROM FolderProcessChecklist
 WHERE FolderProcessChecklist.ProcessRSN = @processRSN
   AND FolderProcessChecklist.ChecklistCode = 10000  /* Administrative */

SELECT @DABChecklistPass = FolderProcessChecklist.Passed
  FROM FolderProcessChecklist
 WHERE FolderProcessChecklist.ProcessRSN = @processRSN
   AND FolderProcessChecklist.ChecklistCode = 10001      /* DAB */

SELECT @CBChecklistPass = FolderProcessChecklist.Passed
  FROM FolderProcessChecklist
 WHERE FolderProcessChecklist.ProcessRSN = @processRSN
   AND FolderProcessChecklist.ChecklistCode = 10002      /* CB */

SELECT @DRBChecklistPass = FolderProcessChecklist.Passed
  FROM FolderProcessChecklist
 WHERE FolderProcessChecklist.ProcessRSN = @processRSN
   AND FolderProcessChecklist.ChecklistCode = 10003      /* DRB */

/* Get ProcessRSN for Project Decision, and check for existence of ProcessInfo 
   field for the Waive Appeal Right Option. And do the same for ZL Appeal to DRB. */

SELECT @ProjDecRSN = dbo.udf_GetZoningDecisionProcessRSN(@FolderRSN)
SELECT @AppealtoDRBProcessRSN = dbo.udf_GetZoningAppealtoDRBProcessRSN(@FolderRSN)

SELECT @WaiveAppealProcessInfoCountProject = COUNT(*)
  FROM FolderProcessInfo
 WHERE FolderProcessInfo.ProcessRSN = @ProjDecRSN
   AND FolderProcessInfo.InfoCode = 10002

SELECT @WaiveAppealProcessInfoCountAppeal = COUNT(*)
  FROM FolderProcessInfo
 WHERE FolderProcessInfo.ProcessRSN = @AppealtoDRBProcessRSN 
   AND FolderProcessInfo.InfoCode = 10002 

/* End processing if both Admin and DRB review checklists are set to Yes. 
   End processing if Admin Review was selected for ZH, ZP and ZS folders. 
   For Z3, Admin Review can be only for Lot Line Adjustment and Mergers. 
   For ZH folders, the exception is for administrative denial of 
   incomplete applications (FolderProcessAttempt.ResultCode = 10051). */

IF @AdminChecklistPass = 'Y' AND @DRBChecklistPass = 'Y'
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Checklists show simultaneous Admin and DRB review. Please correct by setting one to No.', 16, -1)
   RETURN
END

IF @AdminChecklistPass = 'Y' 
BEGIN
   IF @FolderType IN ('ZC', 'ZH', 'ZL', 'ZP', 'ZS') AND @RCLastAttemptCode <> 10051
   BEGIN 
      ROLLBACK TRANSACTION
      RAISERROR ('ZC, ZH, ZL, ZP and ZS folders can not be reviewed administratively', 16, -1)
      RETURN
   END

   IF @FolderType = 'Z3' 
   BEGIN 
      IF dbo.f_info_alpha (@FolderRSN, 10015) NOT IN ('Lot Line Adjustment', 'Lot Merger')
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('Only Lot Line Adjustments and Lot Mergers can be reviewed administratively (See Info)', 16, -1)
         RETURN
      END
   END
END

IF @DRBChecklistPass = 'Y' AND @FolderType = 'ZD' 
BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('ZD folders can not be reviewed by the DRB', 16, -1)
      RETURN
END

/* Setup Complete.  Folder status becomes either In Review (10001), or in the case of 
   appeals of Code Enforcement and other zoning decisions, Appeal to DRB (10009). */

IF @AttemptResult = 10012                   /* Setup Info */
BEGIN
   IF @FolderType = 'ZL'
   BEGIN
      SELECT @AppealText = 
        CASE @WorkCode
           WHEN 10004 THEN 'Appeal of Code Enforcement Determination'
           WHEN 10005 THEN 'Appeal of Misc Zoning Administrative Decision'
           ELSE ' '
        END

      IF @FolderConditions IS NULL
      BEGIN
         UPDATE Folder
            SET Folder.FolderCondition = 'Application for ' + @AppealText + ' Received (' + CONVERT(char(11), @InDate) +')'
          WHERE Folder.FolderRSN = @FolderRSN
      END
   END
   ELSE
   BEGIN
      IF @FolderConditions IS NULL
      BEGIN
    UPDATE Folder
            SET Folder.FolderCondition = 'Application Received (' + CONVERT(char(11), @InDate) +')'
          WHERE Folder.FolderRSN = @FolderRSN
      END
   END

   UPDATE FolderProcessAttempt
      SET FolderProcessAttempt.AttemptBy = @UserID
    WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
      AND FolderProcessAttempt.AttemptRSN = 
          ( SELECT max(FolderProcessAttempt.AttemptRSN) 
              FROM FolderProcessAttempt
             WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

/* Insert or delete associated Info fields. */

/* Administrative Review Y or N */

   IF @AdminChecklistPass = 'Y' 
   BEGIN
      SELECT @AdminNote = 'ADMIN '
      IF @ParentRSN > 0 
      BEGIN 
         UPDATE FolderInfo
            SET FolderInfo.InfoValue = UPPER(@ParentZPNumber), 
       FolderInfo.InfoValueUpper = UPPER(@ParentZPNumber)
          WHERE FolderInfo.InfoCode = 10005
            AND FolderInfo.FolderRSN = @FolderRSN
      END

      UPDATE Folder
         SET Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Administrative Review'))
       WHERE Folder.FolderRSN = @FolderRSN

      IF @AdminInfoField = 0
      BEGIN
         INSERT INTO FolderInfo
                     ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                       StampDate, StampUser, Mandatory, ValueRequired )
              VALUES ( @FolderRSN, 10055,  @AdminOrder, 'Y', getdate(), @UserID, 'N', 'N' )
      END
      ELSE
      IF @AdminInfoValue IS NOT NULL
      BEGIN
         UPDATE FolderInfo
            SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
          WHERE FolderInfo.FolderRSN = @FolderRSN
            AND FolderInfo.InfoCode = 10055
      END
   END

   IF @AdminChecklistPass = 'N' 
   BEGIN
      SELECT @AdminNote = NULL

      IF @Subcode = 10041
      BEGIN
         UPDATE Folder
            SET Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Administrative Review Cancelled'))
          WHERE Folder.FolderRSN = @FolderRSN
      END

      UPDATE Folder
         SET Folder.SubCode = NULL
       WHERE Folder.FolderRSN = @FolderRSN

      IF @AdminInfoField > 0 AND @AdminInfoValue IS NULL
      BEGIN
         DELETE FROM FolderInfo
         WHERE FolderInfo.FolderRSN = @FolderRSN
           AND FolderInfo.InfoCode = 10055
      END
  END

/* Design Advisory Board Y or N */

   IF @DABChecklistPass = 'Y'
   BEGIN
      SELECT @DABNote = 'DAB '
      IF @DABInfoField = 0
      BEGIN
         INSERT INTO FolderInfo
                     ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                      StampDate, StampUser, Mandatory, ValueRequired )
           VALUES ( @FolderRSN, 10003,  @DABOrder, 'Y', getdate(), @UserID, 'N', 'N' )
      END
      ELSE
      IF @DABInfoValue IS NOT NULL
      BEGIN
         UPDATE FolderInfo
            SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
          WHERE FolderInfo.FolderRSN = @FolderRSN
            AND FolderInfo.InfoCode = 10003
      END

      IF @DABStaffCommentsDoc = 0
      BEGIN 
         SELECT @NextDocumentRSN = @NextDocumentRSN + 1
         INSERT INTO FolderDocument
                   ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
                     DisplayOrder, StampDate, StampUser, LinkCode )
            VALUES ( @FolderRSN, 10011, 1, @NextDocumentRSN, 22, getdate(), @UserID, 1 )  
      END
   END

   IF @DABChecklistPass = 'N'
   BEGIN
      SELECT @DABNote = NULL
      IF @DABInfoField > 0 AND @DABInfoValue IS NULL
      BEGIN
         DELETE FROM FolderInfo
               WHERE FolderInfo.FolderRSN = @FolderRSN
           AND FolderInfo.InfoCode = 10003
      END
      IF @DABStaffCommentsDoc > 0 AND @DABStaffCommentsGenerated IS NULL
      BEGIN
         DELETE FROM FolderDocument
               WHERE FolderDocument.FolderRSN = @FolderRSN
                 AND FolderDocument.DocumentCode = 10011
      END
   END

/* Conservation Board Y or N */

   IF @CBChecklistPass = 'Y'
   BEGIN
      SELECT @CBNote = 'CB '
      IF @CBInfoField = 0
      BEGIN
         INSERT INTO FolderInfo
                     ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                       StampDate, StampUser, Mandatory, ValueRequired )
              VALUES ( @FolderRSN, 10007,  @CBOrder, 'Y', getdate(), @UserID, 'N', 'N' )
      END
      ELSE
      IF @CBInfoValue IS NOT NULL
      BEGIN
         UPDATE FolderInfo
            SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
          WHERE FolderInfo.FolderRSN = @FolderRSN
            AND FolderInfo.InfoCode = 10007
      END
   END

   IF @CBChecklistPass = 'N'
   BEGIN
      SELECT @CBNote = NULL
      IF @CBInfoField > 0 AND @CBInfoValue IS NULL 
      BEGIN
         DELETE FROM FolderInfo
               WHERE FolderInfo.FolderRSN = @FolderRSN
                 AND FolderInfo.InfoCode = 10007
      END
   END

/* Development Review Board Y or N */ 

/* Insert or delete DRB checklist from Project Decision process (10005).
   Inserts or deletes DRB-related FolderInfo fields. 
   Insert or delete the Staff Comments document. 
   Codes or nulls Project File Info field with ZP Number. Project File is populated 
   with the ZP Number of the parent folder only if a - (dash) is not present. This 
   prevents overwriting hand-coding. 
   Public Hearing Info fields were discontinued in v.3. 
   The legacy COA fields were discontinued in v.2. All DRB decision dates are in 
   Info field 10049. 
   Insert the DRB or Appeal Findings folder clock 
   Insert or delete Waive Appeal Right ProcessInfo field */

   IF @DRBChecklistPass = 'Y'
   BEGIN
      SELECT @DRBNote = 'DRB '

      UPDATE Folder
         SET Folder.ReferenceFile = UPPER(@ZPNumber), 
             Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> DRB Review'))
       WHERE Folder.FolderRSN = @FolderRSN

      IF @FolderType = 'ZL'  /* Waive Option is in Appeal to DRB by default, but not coded */
      BEGIN
         UPDATE FolderProcessInfo
            SET FolderProcessInfo.InfoValue = 'No', 
                FolderProcessInfo.InfoValueUpper = 'NO'
          WHERE FolderProcessInfo.ProcessRSN = @AppealtoDRBProcessRSN
            AND FolderProcessInfo.InfoCode = 10002
      END
      ELSE    /* Other folder types - insert FolderProcessInfo Waive Option */
      BEGIN
         IF @WaiveAppealProcessInfoCountProject = 0 AND @ProjDecRSN > 0 
         BEGIN
            INSERT INTO FolderProcessInfo
                   (ProcessRSN, InfoCode, InfoValue, InfoValueUpper, 
                    DisplayOrder, StampDate, StampUser, FolderRSN)
            VALUES (@ProjDecRSN, 10002, 'No', 'NO', 10, getdate(), @UserID, @FolderRSN)
         END
      END

      IF @ParentRSN > 0 AND ( @ProjectFile NOT LIKE '%-%' OR @ProjectFile IS NULL )
      BEGIN 
         UPDATE FolderInfo
            SET FolderInfo.InfoValue = UPPER(@ParentZPNumber), 
                FolderInfo.InfoValueUpper = UPPER(@ParentZPNumber)
          WHERE FolderInfo.InfoCode = 10005
            AND FolderInfo.FolderRSN = @FolderRSN
      END

      IF @ParentRSN IS NULL
      BEGIN
         UPDATE FolderInfo
            SET FolderInfo.InfoValue = UPPER(@ZPNumber), 
                FolderInfo.InfoValueUpper = UPPER(@ZPNumber)
          WHERE FolderInfo.InfoCode = 10005
           AND FolderInfo.FolderRSN = @FolderRSN
      END

      EXECUTE dbo.usp_Zoning_FolderInfo_DRB_Setup @FolderRSN, @DRBChecklistPass, @UserID 

      IF @DRBStaffCommentsDoc = 0
      BEGIN 
         SELECT @NextDocumentRSN = @NextDocumentRSN + 1
         INSERT INTO FolderDocument
                   ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
                     DisplayOrder, StampDate, StampUser, LinkCode )
            VALUES ( @FolderRSN, 10000, 1, @NextDocumentRSN, 21, getdate(), @UserID, 1 )  
      END

     IF @DRBFindingsClock = 0 AND @FolderType <> 'ZL' 
     BEGIN
        INSERT INTO FolderClock  
           (FolderRSN, FolderClock, MaxCounter, StartDate, Counter, Status, Colour)
        VALUES 
           (@FolderRSN, 'DRB Findings', 45, getdate(), 0, 'Not Started', 'Blue')
     END

     IF @AppealFindingsClock = 0 AND @FolderType = 'ZL' 
     BEGIN
        INSERT INTO FolderClock  
           (FolderRSN, FolderClock, MaxCounter, StartDate, Counter, Status, Colour)
        VALUES 
           (@FolderRSN, 'Appeal Fdngs', 45, getdate(), 0, 'Not Started', 'Red')
     END

     IF @AdminReviewClock > 0
     BEGIN
        UPDATE FolderClock
           SET FolderClock.Status = 'Stopped'
         WHERE FolderClock.FolderRSN = @FolderRSN
           AND FolderClock.FolderClock = 'Admin Review'
     END

   END  /* End of @DRBChecklistPass = 'Y' */

   IF @DRBChecklistPass = 'N'
   BEGIN
      SELECT @DRBNote = NULL

      IF @SubCode = 10042 
      BEGIN
         UPDATE Folder
            SET Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> DRB Review Cancelled'))
          WHERE Folder.FolderRSN = @FolderRSN
      END

      UPDATE Folder
         SET Folder.SubCode = NULL
       WHERE Folder.FolderRSN = @FolderRSN

      IF @WaiveAppealProcessInfoCountProject > 0
      BEGIN
         UPDATE FolderProcessInfo
            SET FolderProcessInfo.InfoValue = 'No', 
                FolderProcessInfo.InfoValueUpper = 'NO'
          WHERE FolderProcessInfo.ProcessRSN = @ProjDecRSN
            AND FolderProcessInfo.InfoCode = 10002
      END

      IF @FolderType <> 'ZS' AND @ParentRSN = 0
      BEGIN
         UPDATE FolderInfo
            SET FolderInfo.InfoValue = 'NA', FolderInfo.InfoValueUpper = 'NA'
          WHERE FolderInfo.InfoCode = 10005
          AND FolderInfo.FolderRSN = @FolderRSN
      END

      EXECUTE dbo.usp_Zoning_FolderInfo_DRB_Setup @FolderRSN, @DRBChecklistPass, @UserID 

      IF @DRBStaffCommentsDoc > 0 AND @DRBStaffCommentsGenerated IS NULL
      BEGIN
         DELETE FROM FolderDocument
            WHERE FolderDocument.FolderRSN = @FolderRSN
                 AND FolderDocument.DocumentCode = 10000
      END

      IF @DRBFindingsClock > 0
      BEGIN
         DELETE FROM FolderClock
               WHERE FolderClock.FolderRSN = @FolderRSN
                 AND FolderClock.FolderClock = 'DRB Findings'
      END

      IF @AppealFindingsClock > 0
      BEGIN
         DELETE FROM FolderClock
               WHERE FolderClock.FolderRSN = @FolderRSN
                 AND FolderClock.FolderClock = 'Appeal Fdngs'
      END

      IF @AdminReviewClock > 0 AND @FolderStatus = 10001
      BEGIN
         UPDATE FolderClock
      SET FolderClock.Status = 'Running', 
                FolderClock.StartDate = getdate() 
       WHERE FolderClock.FolderRSN = @FolderRSN
            AND FolderClock.FolderClock = 'Admin Review'
      END

      IF @AdminReviewClock > 0 AND @FolderStatus <> 10001
      BEGIN
         UPDATE FolderClock
            SET FolderClock.Status = 'Paused'
          WHERE FolderClock.FolderRSN = @FolderRSN
          AND FolderClock.FolderClock = 'Admin Review'
      END

   END  /* End of @DRBChecklistPass = 'N' */

END     /* End of Attempt Result */

/* Set Folder.SubCode to either Admin or DRB Review. */

IF @AdminChecklistPass = 'Y' 
BEGIN
   UPDATE Folder
      SET Folder.SubCode = 10041
    WHERE Folder.FolderRSN = @FolderRSN
END

IF @DRBChecklistPass = 'Y' 
BEGIN
   UPDATE Folder
      SET Folder.SubCode = 10042
    WHERE Folder.FolderRSN = @FolderRSN
END

/* For appealed applications remanded back to the City by the VSCED, set 
   Folder Status to In Review and open decision processes.  The reason is 
   to force resetting FolderInfo fields for the next pass through the 
   review process. */

   UPDATE Folder
      SET Folder.StatusCode = 10001 
    WHERE Folder.FolderRSN = @FolderRSN
      AND Folder.StatusCode = 10056 

   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 1, FolderProcess.StartDate = NULL, 
          FolderProcess.EndDate = NULL, FolderProcess.ScheduleDate = NULL, 
          FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL 
    WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessCode IN (10005, 10010, 10016)


/* Add Sign and Awning related Info fields (ZA Folder). */

IF @FolderType = 'ZA' 
   EXECUTE dbo.usp_Zoning_Insert_FolderInfo_ZA_Folder @FolderRSN, @UserID 

/* Write username to Project Manager Info field. */

   EXECUTE dbo.usp_Zoning_Update_Project_Manager @FolderRSN, @UserID

/* Write out checklist selections in comment fields, and re-open process for reuse and 
   changes in type of review. This process is closed by Project Decision when 
   decision is made. */

SELECT @varProcessComment = @DRBNote + @DABNOTE + @CBNOTE + @AdminNote
IF @varProcessComment IS NULL SELECT @varProcessComment = 'To Be Determined' 

UPDATE FolderProcessAttempt
   SET FolderProcessAttempt.AttemptComment = @varProcessComment, 
       FolderProcessAttempt.AttemptBy = @UserID
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 1, 
       FolderProcess.ProcessComment = @varProcessComment, 
       FolderProcess.ScheduleDate = getdate(),
       FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
       FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL 
 WHERE FolderProcess.ProcessRSN = @ProcessRSN
   AND FolderProcess.FolderRSN = @FolderRSN

GO
