USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QL_00020010]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QL_00020010]
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
DECLARE @AttemptResult int
DECLARE @NoticeViolation int
DECLARE @NoticeViolationDate datetime

SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @NoticeViolation = count(ResultCode)
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.ResultCode = 20013

  IF @NoticeViolation >0 
  BEGIN
  SELECT @NoticeViolationDate = AttemptDate
  FROM FolderProcessAttempt
  WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
  AND FolderProcessAttempt.ResultCode = 20013
  AND FolderProcessAttempt.AttemptRSN =
                          (SELECT max(FolderProcessAttempt.AttemptRSN)
                           FROM FolderProcessAttempt
                           WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
                           AND FolderProcessAttempt.ResultCode = 20013)
  END

IF @AttemptResult = 20011 /*Legal Action Required*/
BEGIN
  IF @NoticeViolation = 0 
  BEGIN
  ROLLBACK TRANSACTION
    RAISERROR('MUST HAVE SENT NOTICE OF VIOLATION AT LEAST 10 DAYS PRIOR TO
    ANY LEGAL ACTION', 16, -1)
    RETURN
  END

  IF @NoticeViolation >0
  BEGIN
    IF @NoticeViolationDate > getdate()-14
    BEGIN
    ROLLBACK TRANSACTION
    RAISERROR('MUST HAVE SENT NOTICE OF VIOLATION AT LEAST 10 DAYS PRIOR TO
    ANY LEGAL ACTION', 16, -1)
    RETURN
  END 
   

   ELSE IF @NoticeViolationDate <= getdate()-14
   BEGIN

     UPDATE Folder
     SET StatusCode = 110 /*Legal Action*/
     WHERE Folder.FolderRSN = @FolderRSN

     UPDATE FolderComment
     SET FolderComment.IncludeOnToDo = NULL
     WHERE FolderComment.FolderRSN = @FolderRSN
     AND FolderComment.Comments LIKE 'REVIEW PROGRESS OF CONST PERMIT EVALUATION'

     INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
     FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
     VALUES(getdate(), 'REVIEW PROGRESS OF LEGAL ACION', 'KBUTLER',
     @FolderRSN, 'Y', getdate()+30, getdate(), @userID)
   END
END
END

IF @AttemptResult = 20014 /*No Violation*/
BEGIN
  
   UPDATE Folder  /*close the folder*/
   SET StatusCode = 2, FinalDate = getdate()
   WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderProcess  /*close any open processes*/
   SET FolderProcess.EndDate = getdate(), FolderProcess.StatusCode = 2
   WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.EndDate IS NULL

END


IF @AttemptResult = 20016 /*Permit Approved*/
BEGIN

   UPDATE Folder  /*close the folder*/
   SET StatusCode = 2, FinalDate = getdate()
   WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderProcess  /*close any open processes*/
   SET FolderProcess.EndDate = getdate(), FolderProcess.StatusCode = 2
   WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.EndDate IS NULL

END 
  

GO
