USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QZ_00020049]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QZ_00020049]
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
/* Appeal Decision (20049) version 2 */
/* Attempt results changed in version 2. */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int

DECLARE @AppealableDecisionInfoValue varchar(50)
DECLARE @PostAppealDecisionInfoValue varchar(50)
DECLARE @DRBAppealInfoField int
DECLARE @DRBAppealDecisionDate datetime
DECLARE @VECAppealInfoOrder int
DECLARE @VECAppealInfoField int
DECLARE @VECAppealDecisionDate datetime
DECLARE @DecisionDate datetime
DECLARE @ExpiryDate datetime

DECLARE @ReviewBody varchar(3)
DECLARE @InvestigationInfoOrder int
DECLARE @InvestigationProcessOrder int

/* Get Attempt Result */

SELECT @AttemptResult = ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @processRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

/* Get Folder Type, Folder Status, Initialization Date, SubCode values. */

SELECT @FolderType = Folder.FolderType, 
       @FolderStatus = Folder.StatusCode,
       @InDate = Folder.InDate,
       @SubCode = Folder.SubCode
  FROM Folder
 WHERE Folder.FolderRSN = @folderRSN

/* Get Appealable Decision Info field value. */

SELECT @AppealableDecisionInfoValue = FolderInfo.InfoValue
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20068

/* Get DRB and VEC Appeal Decision Date Info field values. Perform checks. 
   Set appeal period expiry date to decision date plus 30 days. */

SELECT @DRBAppealInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20065

SELECT @DRBAppealDecisionDate = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20065

SELECT @VECAppealInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20066

SELECT @VECAppealDecisionDate = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20066

/* Perform some checks, and set decision date and appeal period expiry date */

IF @AttemptResult IN(20112, 20113) AND @VECAppealInfoField = 0
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Folder set up for DRB Decision. Choose a DRB attempt result to continue.', 16, -1)
   RETURN
END

IF @AttemptResult IN(20102, 20103) AND @VECAppealInfoField > 0
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Folder set up for VEC Decision. Choose a VEC attempt result to continue.', 16, -1)
   RETURN
END

IF @DRBAppealInfoField > 0 AND @DRBAppealDecisionDate IS NULL
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter the DRB Appeal Decision Date Info field to continue.', 16, -1)
   RETURN
END

IF @VECAppealInfoField > 0 AND @VECAppealDecisionDate IS NULL
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter the VEC Appeal Decision Date Info field to continue.', 16, -1)
   RETURN
END

IF @VECAppealInfoField = 0 
BEGIN
   SELECT @ReviewBody = 'DRB', @DecisionDate = @DRBAppealDecisionDate
END

IF @VECAppealInfoField > 0 
BEGIN
   SELECT @ReviewBody = 'VEC', @DecisionDate = @VECAppealDecisionDate
END

SELECT @ExpiryDate = @DecisionDate + 30

/* Set appeal period WorkCode values. */

SELECT @WorkCode = 
   CASE @AttemptResult
        WHEN 20102 THEN 20121
        WHEN 20103 THEN 20122
        WHEN 20112 THEN 20123
        WHEN 20113 THEN 20124
   END

/* Set post-appeal value for Appealable Decision Info field. This is used by logon 
   procedure to change folder settings when appeal period expires. */

IF @AppealableDecisionInfoValue = 'Grandfathering - Approved'
BEGIN
   SELECT @PostAppealDecisionInfoValue =
   CASE @AttemptResult
      WHEN 20102 THEN 'Grandfathering - Denied'
      WHEN 20103 THEN 'Grandfathering - Approved'
      WHEN 20112 THEN 'Grandfathering - Denied'
      WHEN 20113 THEN 'Grandfathering - Approved'
   END
END

IF @AppealableDecisionInfoValue = 'Grandfathering - Denied'
BEGIN
   SELECT @PostAppealDecisionInfoValue =
   CASE @AttemptResult
      WHEN 20102 THEN 'Grandfathering - Approved'
      WHEN 20103 THEN 'Grandfathering - Denied'
      WHEN 20112 THEN 'Grandfathering - Approved'
      WHEN 20113 THEN 'Grandfathering - Denied'
   END
END

IF @AppealableDecisionInfoValue = 'Functional Family - Approved'
BEGIN
   SELECT @PostAppealDecisionInfoValue =
   CASE @AttemptResult
      WHEN 20102 THEN 'Functional Family - Denied'
      WHEN 20103 THEN 'Functional Family - Approved'
      WHEN 20112 THEN 'Functional Family - Denied'
      WHEN 20113 THEN 'Functional Family - Approved'
   END
END

IF @AppealableDecisionInfoValue = 'Functional Family - Denied'
BEGIN
   SELECT @PostAppealDecisionInfoValue =
   CASE @AttemptResult
      WHEN 20102 THEN 'Functional Family - Approved'
      WHEN 20103 THEN 'Functional Family - Denied'
      WHEN 20112 THEN 'Functional Family - Approved'
      WHEN 20113 THEN 'Functional Family - Denied'
   END
END

IF @AppealableDecisionInfoValue = 'Zoning Review - Approved'
BEGIN
   SELECT @PostAppealDecisionInfoValue =
   CASE @AttemptResult
      WHEN 20102 THEN 'Zoning Review - Denied'
      WHEN 20103 THEN 'Zoning Review - Approved'
      WHEN 20112 THEN 'Zoning Review - Denied'
      WHEN 20113 THEN 'Zoning Review - Approved'
   END
END

IF @AppealableDecisionInfoValue = 'Zoning Review - Denied'
BEGIN
   SELECT @PostAppealDecisionInfoValue =
   CASE @AttemptResult
      WHEN 20102 THEN 'Zoning Review - Approved'
      WHEN 20103 THEN 'Zoning Review - Denied'
      WHEN 20112 THEN 'Zoning Review - Approved'
      WHEN 20113 THEN 'Zoning Review - Denied'
   END
END

IF @AppealableDecisionInfoValue = 'Investigation - Complaint Unfounded'
BEGIN
   SELECT @PostAppealDecisionInfoValue =
   CASE @AttemptResult
      WHEN 20102 THEN 'Investigation - Notice of Violation'
      WHEN 20103 THEN 'Investigation - Complaint Unfounded'
      WHEN 20112 THEN 'Investigation - Notice of Violation'
      WHEN 20113 THEN 'Investigation - Complaint Unfounded'
   END
END

IF @AppealableDecisionInfoValue = 'Investigation - Notice of Violation'
BEGIN
   SELECT @PostAppealDecisionInfoValue =
   CASE @AttemptResult
      WHEN 20102 THEN 'Investigation - Complaint Unfounded'
      WHEN 20103 THEN 'Investigation - Notice of Violation'
      WHEN 20112 THEN 'Investigation - Complaint Unfounded'
      WHEN 20113 THEN 'Investigation - Notice of Violation'
   END
END

/* DRB Overturns Administrative Decision attempt result */

IF @AttemptResult = 20102
BEGIN

   UPDATE Folder
      SET Folder.WorkCode = @WorkCode, Folder.IssueDate = @DecisionDate, 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> ' + @ReviewBody + ' Overturns Administrative Decision In Appeal (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = @ReviewBody + ' Overturns Administrative Decision',
           FolderProcess.EndDate = getdate(), 
  FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
  AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
   SET FolderProcessAttempt.AttemptComment = 'Decision: Overturn Administrative Decision (' + CONVERT(char(11), @DecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

END    /* end of DRB Overturns Administrative Decision attempt result */

/* DRB Upholds Administrative Decision attempt result */

IF @AttemptResult = 20103
BEGIN

   UPDATE Folder
      SET Folder.WorkCode = @WorkCode, Folder.IssueDate = @DecisionDate, 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> ' + @ReviewBody + ' Upholds Administrative Decision In Appeal (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = @ReviewBody + ' Upholds Administrative Decision',
           FolderProcess.EndDate = getdate(), 
  FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Decision: Uphold Administrative Decision (' + CONVERT(char(11), @DecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

END    /* end of DRB Upholds Administrative Decision attempt result */

/* VEC Overturns DRB Decision attempt result */

IF @AttemptResult = 20112
BEGIN

   UPDATE Folder
      SET Folder.WorkCode = @WorkCode, Folder.IssueDate = @DecisionDate, 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> ' + @ReviewBody + ' Overturns DRB Decision In Appeal (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = @ReviewBody + ' Overturns DRB Decision',
           FolderProcess.EndDate = getdate(), 
  FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Decision: Overturn DRB Decision (' + CONVERT(char(11), @DecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

END    /* end of VEC Overturns DRB Decision attempt result */

/* VEC Upholds DRB Decision attempt result */

IF @AttemptResult = 20113
BEGIN

   UPDATE Folder
      SET Folder.WorkCode = @WorkCode, Folder.IssueDate = @DecisionDate, 
          Folder.ExpiryDate = @ExpiryDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> ' + @ReviewBody + ' Upholds DRB Decision In Appeal (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = @ReviewBody + ' Upholds DRB Decision',
           FolderProcess.EndDate = getdate(), 
  FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Decision: Uphold DRB Decision (' + CONVERT(char(11), @DecisionDate) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

END    /* end of VEC Upholds DRB Decision attempt result */

/* Update Appealable Decision Info field with resultant value. 
   Process closes; re-open Initiate Appeal process. */

UPDATE FolderInfo
   SET FolderInfo.InfoValue = @PostAppealDecisionInfoValue, 
       FolderInfo.InfoValueUpper = UPPER(@PostAppealDecisionInfoValue)
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20068

UPDATE FolderProcess
   SET StatusCode = 1, EndDate = NULL
 WHERE FolderProcess.ProcessCode = 20050
   AND FolderProcess.FolderRSN = @folderRSN

GO
