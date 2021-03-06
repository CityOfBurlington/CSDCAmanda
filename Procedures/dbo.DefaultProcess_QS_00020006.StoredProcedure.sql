USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QS_00020006]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QS_00020006]
@ProcessRSN int, @FolderRSN int, @UserId char(8)
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


IF @AttemptResult = 20055 /*Casual Contact*/
BEGIN
UPDATE
FolderProcess
SET FolderProcess.StatusCode = 1, ScheduleDate = getdate() +1, EndDate = Null
WHERE FolderProcess.ProcessRSN = @ProcessRSN
AND FolderProcess.FolderRSN = @FolderRSN
END

IF @AttemptResult = 20022 /*Refer to CEDO*/
BEGIN
INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
  FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
  VALUES(getdate(), 'SANDWICH BOARD VIOLATION REVIEW - CONTACT OWNER', 'EANTCZAK',
  @FolderRSN, 'Y', getdate()+10, getdate(), @userID)

UPDATE
FolderProcess
SET FolderProcess.StatusCode = 1, ScheduleDate = getdate() +5, EndDate = Null
WHERE FolderProcess.ProcessRSN = @ProcessRSN
AND FolderProcess.FolderRSN = @FolderRSN
END


IF @AttemptResult = 20001 /*Issue Warning */
BEGIN
UPDATE
FolderProcess
SET FolderProcess.StatusCode = 1, ScheduleDate = getdate() +1, EndDate = Null
WHERE FolderProcess.ProcessRSN = @ProcessRSN
AND FolderProcess.FolderRSN = @FolderRSN

UPDATE 
Folder
SET Folder.StatusCode = 20001 /*Warning Issued*/
WHERE Folder.FolderRSN = @FolderRSN
END



IF @AttemptResult = 20007 /*Issue Ticket/Order */
BEGIN
UPDATE
FolderProcess
SET FolderProcess.StatusCode = 1, ScheduleDate = getdate() +3, EndDate = Null
WHERE FolderProcess.ProcessRSN = @ProcessRSN
AND FolderProcess.FolderRSN = @FolderRSN

UPDATE 
Folder
SET Folder.StatusCode = 20003 /*Ticket/Order Issued*/
WHERE Folder.FolderRSN = @FolderRSN

EXECUTE DefaultFee_QS_10 @FolderRSN, @UserID

END

IF @AttemptResult = 20018 /*Violation Resolved */
BEGIN
UPDATE 
Folder
SET Folder.StatusCode = 2 /*Closed*/
WHERE Folder.FolderRSN = @FolderRSN
END


IF @AttemptResult = 20057 /*Trashed */
BEGIN
UPDATE
Folder
SET Folder.StatusCode = 2 /*Closed*/, Folder.FolderDescription = 'Sign Confiscated by Code Enforcement and Trashed on ' + Convert(Char(11), getdate())
WHERE Folder.FolderRSN = @FolderRSN
END


IF @AttemptResult = 20011 /*Legal Action Required */
BEGIN
UPDATE
Folder
SET Folder.StatusCode = 110/*Legal Action*/
WHERE Folder.FolderRSN = @FolderRSN
END



IF @AttemptResult = 20056 /*Confiscation*/
BEGIN
   DECLARE @SubType int
   DECLARE @PermitFolder int
   DECLARE @PropertyID int

   SELECT @SubType = Folder.SubCode
   FROM Folder
   WHERE Folder.FolderRSN = @FolderRSN

   SELECT @PropertyID = Folder.PropertyRSN
   FROM Folder
   WHERE Folder.FolderRSN = @FolderRSN

   UPDATE
   Folder
   SET Folder.StatusCode = 20014 /*Violation*/
   WHERE Folder.FolderRSN = @FolderRSN
   
   UPDATE
   FolderProcess
   SET FolderProcess.StatusCode = 1, ScheduleDate = getdate() +30, EndDate = Null, 
   FolderProcess.ProcessComment = 'Trash Sign in 30 days'
   WHERE FolderProcess.ProcessRSN = @ProcessRSN
   AND FolderProcess.FolderRSN = @FolderRSN
   
   IF @SubType IN (20056,20058)
   BEGIN
   SELECT @PermitFolder = Folder.FolderRSN
   FROM Folder
   WHERE Folder.FolderType = 'SB'
   AND Folder.PropertyRSN = @PropertyID

   DECLARE @SBProcessRSN int
   DECLARE @NextAttemptRSN int

   SELECT @SBProcessRSN = FolderProcess.ProcessRSN
   FROM FolderProcess
   WHERE FolderProcess.FolderRSN = @PermitFolder
   AND FolderProcess.ProcessCode = 30101

   SELECT @NextAttemptRSN = IsNull(Max(FolderProcessAttempt.AttemptRSN),0) + 1
   FROM FolderProcessAttempt
   WHERE FolderProcessAttempt.ProcessRSN = @SBProcessRSN
   AND FolderProcessAttempt.FolderRSN = @PermitFolder
   
   INSERT INTO
   FolderProcessAttempt
   (FolderRSN,ProcessRSN,AttemptRSN, ResultCode, AttemptDate,AttemptBy, StampUser,StampDate)
   VALUES
   (@PermitFolder, @SBProcessRSN, @NextAttemptRSN ,30102,getdate(),@UserID,user,getdate())

   UPDATE
   Folder
   SET Folder.StatusCode = 30006 /*Revoked */, issuedate = null, issueuser = null, finaldate = getdate(),
   Folder.FolderDescription = 'Sign Confiscated by Code Enforcement ' + Convert(Char(11),getdate())
   WHERE Folder.FolderRSN = @PermitFolder
   END

END
   

IF @AttemptResult = 30103 /*Notified Insurance Expired*/
BEGIN
   UPDATE
   FolderProcess
   SET FolderProcess.StatusCode = 1, ScheduleDate = getdate() +5, EndDate = Null, 
   FolderProcess.ProcessComment = 'Check for New proof of Insurance '
   WHERE FolderProcess.ProcessRSN = @ProcessRSN
   AND FolderProcess.FolderRSN = @FolderRSN
END
   

IF @AttemptResult = 30104 /*Notified Taxes Due*/
BEGIN
   UPDATE
   FolderProcess
   SET FolderProcess.StatusCode = 1, ScheduleDate = getdate() +5, EndDate = Null, 
   FolderProcess.ProcessComment = 'Check for Payment of Taxes '
   WHERE FolderProcess.ProcessRSN = @ProcessRSN
   AND FolderProcess.FolderRSN = @FolderRSN
END

GO
