USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010028]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010028]
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
/* Waive Right to Appeal (10028) version 1 */

/* This ends the appeal period by setting Folder.StatusCode, and closing processes. 
    This does the same thing as dbo.uspZoningFolderCleanup using the function,  
    dbo.udf_ZoningAppealPeriodEndFolderStatus. */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @StatusCode int
DECLARE @ExpiryDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @ProjectDecisionRSN int
DECLARE @AppealtoDRBRSN int
DECLARE @WaiveAppealProcessInfoValue varchar(4)
DECLARE @NextStatusCode int

/* Get Attempt Result, and other folder values.  */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

SELECT @FolderType = Folder.FolderType, 
       @StatusCode = Folder.StatusCode, 
       @ExpiryDate = Folder.ExpiryDate, 
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

SELECT @ProjectDecisionRSN = FolderProcess.ProcessRSN
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10005

SELECT @AppealtoDRBRSN = FolderProcess.ProcessRSN
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 10002

IF @AppealtoDRBRSN = NULL
BEGIN
   SELECT @WaiveAppealProcessInfoValue = FolderProcessInfo.InfoValueUpper
     FROM FolderProcessInfo
    WHERE FolderProcessInfo.ProcessRSN = @ProjectDecisionRSN
      AND FolderProcessInfo.InfoCode = 10002
END
ELSE 
BEGIN
   SELECT @WaiveAppealProcessInfoValue = FolderProcessInfo.InfoValueUpper
     FROM FolderProcessInfo
    WHERE FolderProcessInfo.ProcessRSN = @AppealtoDRBRSN
   AND FolderProcessInfo.InfoCode = 10002
END

/* Error checks: Folder status must be in a decision appeal period.  
   FolderProcessInfo Waive Appeal Period Option must be Yes. */

IF @StatusCode NOT IN (10002, 10003, 10004, 10016, 10022, 10027, 10044, 10045)
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Folder is not in an appeal period, and therefore appeal rights can not be waived. Exitting.', 16, -1)
   RETURN
END

IF  @WaiveAppealProcessInfoValue <> 'YES'
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('ProcessInfo Waive Right to Appeal Option for Project Decision must be set to Yes.  Please exit and correct.', 16, -1)
   RETURN
END

IF @AttemptResult = 10058                   /* Appeal Right Waived */
BEGIN
   SELECT @NextStatusCode = dbo.udf_ZoningAppealPeriodEndFolderStatus (@FolderRSN)

   UPDATE Folder
      SET Folder.StatusCode = @NextStatusCode, 
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Appeal Right Waived by Owner (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Right Waived',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @FolderRSN
       AND FolderProcess.ProcessRSN = @ProcessRSN

   /* Close open processes for permits out of appeal periods, except 
       Pre-Release Conditions and CO-related processes. */

   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate()
    WHERE FolderProcess.ProcessCode IN (10000, 10002, 10003, 
                          10004, 10005, 10007, 10008, 10009, 10010, 10011, 
                          10012, 10013, 10014, 10015, 10016, 10018, 10020, 
                          10028, 10029 ) 
      AND FolderProcess.StatusCode = 1 
      AND FolderProcess.FolderRSN = @FolderRSN
END

GO
