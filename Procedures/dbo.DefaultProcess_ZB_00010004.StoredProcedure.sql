USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010004]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010004]
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
/* Revoke Permit (10004) version 2 */
/* Relinquish Permit moved to process 10019 - Permit Termination 6/30/09 */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @InDate datetime
DECLARE @DecisionDate datetime
DECLARE @ExpiryDate datetime

/* Get Attempt Result, and other folder values. */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

SELECT @FolderType = Folder.FolderType,
       @InDate = Folder.InDate, 
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

SELECT @DecisionDate = getdate()
SELECT @ExpiryDate   = DATEADD(DAY, 15, getdate())

/* Permit is Revoked: Update folder status, set folder decision and appeal period 
   expiration dates. Reopen Initiate Appeal. */

IF @AttemptResult = 10040                   /* Revoke Permit */
BEGIN
   UPDATE Folder
      SET Folder.StatusCode = 10022, Folder.ExpiryDate = @ExpiryDate, 
          Folder.IssueDate = @DecisionDate, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Permit Revoked (' + CONVERT(char(11), @DecisionDate) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Revoked',
           FolderProcess.ScheduleDate = getdate(),
           FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Revoked (' + CONVERT(char(11), @DecisionDate) + ')', 
        FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

    UPDATE FolderProcess
       SET FolderProcess.StatusCode = 1, FolderProcess.StartDate = NULL, 
           FolderProcess.EndDate = NULL, FolderProcess.ScheduleDate = getdate(), 
           FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL, 
           FolderProcess.ProcessComment = NULL
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessCode = 10008

END

GO
