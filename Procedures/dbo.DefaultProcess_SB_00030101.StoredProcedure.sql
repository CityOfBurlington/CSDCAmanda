USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_SB_00030101]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_SB_00030101]
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


SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)


IF @AttemptResult = 30106 /*Refer to Code Enforcement*/
BEGIN
 INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
  FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
  VALUES(getdate(), 'REVIEW SANDWICH BOARD ISSUE FOR POSSIBLE VIOALTION', 'KBUTLER',
  @FolderRSN, 'Y', getdate(), getdate(), @userID)


UPDATE
FolderProcess
SET StatusCode = 1, EndDate = Null
WHERE FolderProcess.FolderRSN = @FolderRSN
AND FolderProcess.ProcessRSN = @ProcessRSN

END



IF @AttemptResult = 30102 /*Removed */
BEGIN
UPDATE
FOLDER
SET Folder.StatusCode = 2 /*Closed*/, Folder.IssueDate = Null, Folder.IssueUser = Null, 
Folder.ExpiryDate = Null, Folder.FolderDescription = 'Sign Removed'
WHERE Folder.FolderRSN = @FolderRSN

END


IF @AttemptResult = 30101 /*Failed*/
BEGIN
UPDATE
FolderProcess
SET FolderProcess.StatusCode = 1, ScheduleDate = getdate()+1
WHERE FolderProcess.ProcessRSN = @ProcessRSN
AND FolderProcess.FolderRSN = @FolderRSN

END


IF @AttemptResult = 60 /*Cancelled*/
BEGIN
UPDATE
Folder
SET Folder.StatusCode = 2 /*Closed*/, Folder.Finaldate = getdate(),ExpiryDate = NULL,
Folder.FolderDescription = 'Permit Cancelled', issuedate = NULL, issueuser = NULL
WHERE 
Folder.FolderRSN = @FolderRSN
END



GO
