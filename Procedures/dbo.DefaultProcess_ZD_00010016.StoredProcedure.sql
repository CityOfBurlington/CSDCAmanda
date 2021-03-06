USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZD_00010016]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZD_00010016]
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
/* Determination Findings (10016) */

DECLARE @AttemptResult int
DECLARE @AttemptDate datetime
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @ZPNumber varchar(10)
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @AdminDecisionDate datetime
DECLARE @DecisionDate datetime
DECLARE @ExpiryDate datetime
DECLARE @NextStatusCode int
DECLARE @PermitPickedupInfoOrder int
DECLARE @PermitPickedupInfoField int
DECLARE @PermitPickedupInfoValue varchar(10)
DECLARE @FindingsDoc int
DECLARE @FindingsDocNotGenerated int
DECLARE @FindingsDocDisplayOrder int
DECLARE @AdminReviewClock int
DECLARE @DRBFindingsClock int

/* Get Attempt Result */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

/* Get Folder Type, Folder Status, Application Date, ZP Number, SubCode, WorkCode, 
   Conditions, and ParentRSN. */

SELECT @FolderType = Folder.FolderType, 
       @FolderStatus = Folder.StatusCode,
       @InDate = Folder.InDate,
       @ZPNumber = Folder.ReferenceFile, 
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

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

/* Check for existence of DRB Findings and Admin Review folder clocks. */

SELECT @AdminReviewClock = COUNT(*)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'Admin Review'

SELECT @DRBFindingsClock = COUNT(*)
  FROM FolderClock
 WHERE FolderClock.FolderRSN = @FolderRSN
   AND FolderClock.FolderClock = 'DRB Findings'

/* Get decision date and set appeal period expiration date. */

SELECT @DecisionDate = @AdminDecisionDate
SELECT @ExpiryDate = DATEADD(day, 15, @DecisionDate)   /* Appeal period for administrative review */

/* Set next Folder.StatusCode according to attempt result. */

SELECT @NextStatusCode = dbo.udf_GetZoningDecisionNextStatusCode(@FolderRSN, @AttemptResult)

/* Findings Affirmative attempt result */

IF @AttemptResult = 10046
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
   Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Determination Findings: Affirmative (' + CONVERT(char(11), @DecisionDate) + ')'))
 WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Determination Affirmative',
           FolderProcess.ScheduleDate = getdate(),
           FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Affirmative (' + CONVERT(char(11), @DecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )
END

/* Findings Adverse attempt result */

IF @AttemptResult = 10047
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Determination Findings: Adverse (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Determination Adverse',
           FolderProcess.ScheduleDate = getdate(),
           FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Adverse (' + CONVERT(char(11), @DecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )
END

/* Add Determination Findings document */

SELECT @FindingsDoc = ISNULL(count(*),0)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @folderRSN
   AND FolderDocument.DocumentCode = 10013

SELECT @FindingsDocNotGenerated = ISNULL(count(*),0)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @folderRSN
   AND FolderDocument.DocumentCode = 10013
   AND FolderDocument.DateGenerated IS NULL

SELECT @FindingsDocDisplayOrder = 10 + @FindingsDoc

IF @FindingsDoc = 0 OR @FindingsDocNotGenerated = 0
BEGIN
   SELECT @NextDocumentRSN =MAX(FolderDocument.DocumentRSN) + 1
     FROM FolderDocument

   INSERT INTO FolderDocument
             ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
               DisplayOrder, StampDate, StampUser, LinkCode )
      VALUES ( @FolderRSN, 10013, 1, @NextDocumentRSN, 
               @FindingsDocDisplayOrder, getdate(), @UserID, 1 )  
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

/* Update Project Manager Info field. */

   EXECUTE dbo.usp_Zoning_Update_Project_Manager @FolderRSN, @UserID

/* Close Review Submission (10015) and Review Clock (10007). Determination Findings  
   also closes. Stop the Admin Review folder clock. */

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 2
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode IN(10007, 10015)
   AND FolderProcess.StatusCode = 1

IF @AdminReviewClock > 0 
BEGIN
   UPDATE FolderClock
      SET FolderClock.Status = 'Stopped'
    WHERE FolderClock.FolderRSN = @FolderRSN
      AND FolderClock.FolderClock = 'Admin Review'
END

IF @DRBFindingsClock > 0
BEGIN
   UPDATE FolderClock
      SET FolderClock.Status = 'Stopped'
    WHERE FolderClock.FolderRSN = @FolderRSN
      AND FolderClock.FolderClock = 'DRB Findings'
END

GO
