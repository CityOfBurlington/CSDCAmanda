USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QZ_00020047]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QZ_00020047]
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
/* Violation Resolution (20047) version 1 */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @InExpiryDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @ExpiryDate datetime

DECLARE @AppealableDecisionInfoOrder int
DECLARE @DRBAppealDateInfoOrder int
DECLARE @VECAppealDateInfoOrder int
DECLARE @MuniTicket1DateInfoOrder int
DECLARE @MuniTicket2DateInfoOrder int
DECLARE @MuniTicket3DateInfoOrder int

DECLARE @StipTermInfoOrder int
DECLARE @StipTermInfoField int
DECLARE @StipTermInfoValue int
DECLARE @StipAgreementDateInfoOrder int
DECLARE @StipAgreementDateInfoField int
DECLARE @StipAgreementDateInfoValue datetime
DECLARE @LitigationDecisionDateInfoOrder int
DECLARE @LitigationDecisionDateInfoField int
DECLARE @LitigationDecisionDateInfoValue datetime

DECLARE @InitiateAppealStatus int
DECLARE @InvestigationProcessOrder int
DECLARE @RemedyVerifyProcess int
DECLARE @RemedyVerifyProcessOrder int

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
       @InExpiryDate = Folder.ExpiryDate,
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @folderRSN

/* Check to see if Initiate Appeal has been run so the Violation Finality Info 
   field is correctly set. */

SELECT @InitiateAppealStatus = FolderProcess.StatusCode
  FROM FolderProcess
 WHERE FolderProcess.ProcessCode = 20050
   AND FolderProcess.FolderRSN = @FolderRSN

IF @InitiateAppealStatus <> 2 AND @InExpiryDate < getdate()
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please run the Initiate Appeal process to continue.', 16, -1)
   RETURN
END

/* Set Info field display orders, check for existence, and get values. */

SELECT @AppealableDecisionInfoOrder = ISNULL(FolderInfo.DisplayOrder, 200)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20068

SELECT @DRBAppealDateInfoOrder          = @AppealableDecisionInfoOrder + 10
SELECT @VECAppealDateInfoOrder       = @AppealableDecisionInfoOrder + 20
SELECT @MuniTicket1DateInfoOrder        = @AppealableDecisionInfoOrder + 30
SELECT @MuniTicket2DateInfoOrder        = @AppealableDecisionInfoOrder + 40
SELECT @MuniTicket3DateInfoOrder        = @AppealableDecisionInfoOrder + 50
SELECT @StipTermInfoOrder               = @AppealableDecisionInfoOrder + 60
SELECT @StipAgreementDateInfoOrder      = @AppealableDecisionInfoOrder + 70
SELECT @LitigationDecisionDateInfoOrder = @AppealableDecisionInfoOrder + 80

SELECT @StipTermInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20067

SELECT @StipAgreementDateInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20062

SELECT @LitigationDecisionDateInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20063

/* Set Remedy Verification process order, and check for existence. */

SELECT @InvestigationProcessOrder = ISNULL(FolderProcess.DisplayOrder, 100)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 20046

SELECT @RemedyVerifyProcessOrder = @InvestigationProcessOrder + 100

SELECT @RemedyVerifyProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 20053

/* Litigation Initiated attempt result. */

IF @AttemptResult = 20098
BEGIN

   UPDATE Folder
      SET Folder.SubCode = 20065, Folder.WorkCode = 20106, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Litigation Initiated (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Litigation Initiated',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Litigation Initiated (' + CONVERT(char(11), getdate()) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   IF @LitigationDecisionDateInfoField = 0
   BEGIN
   INSERT INTO FolderInfo
                  ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                    StampDate, StampUser, Mandatory, ValueRequired )
           VALUES ( @FolderRSN, 20063, @LitigationDecisionDateInfoOrder, 'Y', 
                     getdate(), @UserID, 'N', 'N' )
   END

   UPDATE FolderProcess
      SET StatusCode = 2, FolderProcess.EndDate = getdate(), 
          FolderProcess.BaseLineEndDate = getdate()
    WHERE FolderProcess.StatusCode = 1
      AND FolderProcess.ProcessCode IN(20042, 20043, 20044, 20045, 20046, 
                                       20049, 20050, 20051, 20052)
      AND FolderProcess.FolderRSN = @folderRSN

END

/* Stipulation Agreement Sought attempt result. */

IF @AttemptResult = 20099
BEGIN

   UPDATE Folder
      SET Folder.SubCode = 20065, Folder.WorkCode = 20125, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Stipulation Agreement Sought (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Stipulation Agreement Sought',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Stipulation Agreement Sought (' + CONVERT(char(11), getdate()) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   IF @StipTermInfoField = 0
   BEGIN
   INSERT INTO FolderInfo
                  ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                    StampDate, StampUser, Mandatory, ValueRequired )
           VALUES ( @FolderRSN, 20067, @StipTermInfoOrder, 'Y', 
                     getdate(), @UserID, 'N', 'N' )
   END

   IF @StipAgreementDateInfoField = 0
   BEGIN
   INSERT INTO FolderInfo
                  ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
            StampDate, StampUser, Mandatory, ValueRequired )
           VALUES ( @FolderRSN, 20062, @StipAgreementDateInfoOrder, 'Y', 
                     getdate(), @UserID, 'N', 'N' )
   END

END

/* Stipulation Agreement Reached attempt result. */

IF @AttemptResult = 20116
BEGIN

   IF @StipTermInfoField = 0 OR @StipAgreementDateInfoField = 0
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please choose a different attempt result to continue.', 16, -1)
      RETURN
   END

   SELECT @StipTermInfoValue = ISNULL(FolderInfo.InfoValueNumeric, 0)
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20067

   SELECT @StipAgreementDateInfoValue = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20062

   IF @StipTermInfoValue = 0
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter the Stipulation Agreement Term (days) Info field to continue.', 16, -1)
      RETURN
   END

   IF @StipAgreementDateInfoValue IS NULL
   BEGIN
   ROLLBACK TRANSACTION
      RAISERROR ('Please enter the Stipulation Agreement Date Info field to continue.', 16, -1)
      RETURN
   END

   SELECT @ExpiryDate = DATEADD(day, @StipTermInfoValue, @StipAgreementDateInfoValue) 

   UPDATE Folder
      SET Folder.WorkCode = 20114, Folder.IssueDate = @StipAgreementDateInfoValue, 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Stipulation Agreement Reached (' + CONVERT(char(11), @StipAgreementDateInfoValue) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Stipulation Agreement Reached',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
      AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Stipulation Agreement Reached (' + CONVERT(char(11), @StipAgreementDateInfoValue) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

END

/* Litigation Complete attempt result. */

IF @AttemptResult = 20117
BEGIN

   IF @LitigationDecisionDateInfoField = 0
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please choose a different attempt result to continue.', 16, -1)
      RETURN
   END

   SELECT @LitigationDecisionDateInfoValue = FolderInfo.InfoValueDateTime
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20063

   IF @LitigationDecisionDateInfoValue IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter the Litigation Decision Date Info field to continue.', 16, -1)
      RETURN
   END

   SELECT @ExpiryDate = DATEADD(day, 30, @LitigationDecisionDateInfoValue)

   UPDATE Folder
      SET Folder.WorkCode = 20127, Folder.IssueDate = @LitigationDecisionDateInfoValue, 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Litigation Complete (' + CONVERT(char(11), @LitigationDecisionDateInfoValue) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Litigation Complete',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Litigation Complete (' + CONVERT(char(11), @LitigationDecisionDateInfoValue) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
            WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

END

/* Violation Remedied attempt result. Added 10/31/07.  This is a get-out-jail-free 
   option where the property owner fixes the violation after receiving the NOV. 
   A 30-day expiration date is set. The login procedure does not do anything 
   with this. */

IF @AttemptResult = 20135
BEGIN

   SELECT @ExpiryDate = DATEADD(day, 30, getdate())

   UPDATE Folder
      SET Folder.WorkCode = 20129, Folder.IssueDate = getdate(), 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Violation Remedied (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Violation Remedied',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Violation Remedied (' + CONVERT(char(11), getdate()) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

END

/* Reopen process for Stipulation Agreement Sought and Litigation Initiated.  
   Close all open processes and add Remedy Verification for Stipulation Agreement 
   Reached, Litigation Complete, and Remedy Verified. */

IF @AttemptResult IN(20098, 20099)
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 1, 
          FolderProcess.ScheduleDate = getdate(),
          FolderProcess.EndDate = NULL, 
          FolderProcess.SignOffUser = NULL
    WHERE FolderProcess.ProcessCode = 20047
      AND FolderProcess.ProcessRSN = @processRSN
      AND FolderProcess.FolderRSN = @folderRSN
END

IF @AttemptResult IN(20116, 20117, 20135)
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 2, 
          FolderProcess.EndDate = getdate(), FolderProcess.BaseLineEndDate = getdate()
    WHERE FolderProcess.StatusCode = 1
      AND FolderProcess.ProcessCode IN(20042, 20043, 20044, 20045, 20046, 20047, 
                                       20049, 20050, 20051, 20052)
      AND FolderProcess.FolderRSN = @FolderRSN

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

GO
