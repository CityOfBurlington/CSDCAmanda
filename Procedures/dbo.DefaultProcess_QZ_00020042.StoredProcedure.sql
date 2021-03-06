USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QZ_00020042]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QZ_00020042]
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
/* Show Cause Response (20042) version 4 */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @FolderConditions varchar(2000)
DECLARE @InvestigationProcessStatus int
DECLARE @SCDateInfoValue datetime
DECLARE @SCMemoDocGenerated datetime
DECLARE @SCMemoTerm int
DECLARE @SCExpiryDate datetime

/* Get Attempt Result */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @processRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

/* Get Folder Type, Folder Status, Initialization Date, SubCode, WorkCode, and
   Conditions values. */

SELECT @FolderType = Folder.FolderType, 
       @FolderStatus = Folder.StatusCode,
       @InDate = Folder.InDate,
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode,
       @FolderConditions = Folder.FolderCondition
  FROM Folder
 WHERE Folder.FolderRSN = @folderRSN

/* Get Show Cause Memo info. */

SELECT @SCDateInfoValue = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20052

SELECT @SCMemoDocGenerated = FolderDocument.DateGenerated
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @folderRSN
   AND FolderDocument.DocumentCode = 20001

SELECT @InvestigationProcessStatus = ISNULL(FolderProcess.StatusCode, 2)
  FROM FolderProcess
 WHERE FolderProcess.ProcessCode = 20046
   AND FolderProcess.FolderRSN = @folderRSN

/* Extend Show Cause Memo Deadline attempt result */

IF @AttemptResult = 20088
BEGIN

   SELECT @SCMemoTerm = ISNULL(FolderInfo.InfoValueNumeric, 0)
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @folderRSN
      AND FolderInfo.InfoCode = 20064

   IF @SCMemoTerm <= 10
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Set the SC Memo Term number of days to be greater than the initial 10 days in order to proceed.', 16, -1)
      RETURN
   END

   IF @SCDateInfoValue IS NULL
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('The Show Cause Memo Date (Info) must be entered to proceed.', 16, -1)
      RETURN
   END

   SELECT @SCExpiryDate = @SCDateInfoValue + @SCMemoTerm

      UPDATE Folder
         SET Folder.WorkCode = 20111, Folder.ExpiryDate = @SCExpiryDate, 
             Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Response Received (' + CONVERT(char(11), getdate()) + 
                                      ') -> Deadline for SC Memo Response Extended to ' + CAST(@SCMemoTerm AS varchar) + ' Days (' + CONVERT(char(11), @SCExpiryDate) + ')'))
       WHERE Folder.FolderRSN = @folderRSN

   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Extend SC Memo Deadline',
          FolderProcess.EndDate = NULL, 
          FolderProcess.AssignedUser = @UserID
    WHERE FolderProcess.ProcessRSN = @processRSN
      AND FolderProcess.FolderRSN = @folderRSN

      UPDATE FolderProcessAttempt
         SET FolderProcessAttempt.AttemptComment = 'Extend SC Memo Deadline to '  + CAST(@SCMemoTerm AS varchar) + ' Days', 
             FolderProcessAttempt.AttemptBy = @UserID
       WHERE FolderProcessAttempt.ProcessRSN = @processRSN
         AND FolderProcessAttempt.AttemptRSN = 
             ( SELECT max(FolderProcessAttempt.AttemptRSN) 
                 FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

END   /* End of Extend Show Cause Memo Deadline attempt result */

/* Inadequate Documentation Provided attempt result */

IF @AttemptResult = 20111
BEGIN

   UPDATE Folder
      SET Folder.SubCode = 20064, Folder.WorkCode = 20105, 
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Inadequate Documentation Provided -> Initiate Formal Investigation (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Inadequate Documentation Provided',
          FolderProcess.EndDate = NULL, 
          FolderProcess.AssignedUser = @UserID
    WHERE FolderProcess.ProcessRSN = @processRSN
      AND FolderProcess.FolderRSN = @folderRSN

   UPDATE FolderProcessAttempt
      SET FolderProcessAttempt.AttemptComment = 'Inadequate Documentation Provided (' + CONVERT(char(11), getdate()) + ')', 
          FolderProcessAttempt.AttemptBy = @UserID
    WHERE FolderProcessAttempt.ProcessRSN = @processRSN
      AND FolderProcessAttempt.AttemptRSN = 
          ( SELECT max(FolderProcessAttempt.AttemptRSN) 
              FROM FolderProcessAttempt
             WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   IF @InvestigationProcessStatus <> 1
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 20046
         AND FolderProcess.FolderRSN = @folderRSN
   END

END   /* End of Inadequate Documentation Provided attempt result */

/* Re-open process for Extend SC Memo Deadline; otherwise it closes. */

IF @AttemptResult = 20088
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 1, 
          FolderProcess.ScheduleDate = getdate(),
          FolderProcess.EndDate = NULL, 
          FolderProcess.SignOffUser = NULL
    WHERE FolderProcess.ProcessRSN = @processRSN
      AND FolderProcess.FolderRSN = @folderRSN
END

GO
