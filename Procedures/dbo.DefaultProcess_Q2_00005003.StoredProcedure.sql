USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_Q2_00005003]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_Q2_00005003]
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
DECLARE @InspectorID char(8)


SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

IF @AttemptResult = 5016 /*Cancelled*/
BEGIN
UPDATE Folder
SET Folder.StatusCode = 2, Folder.FinalDate = getdate(),
Folder.FolderCondition = 'COMPLAINT CANCELLED' + ' ' + Convert(Char(11),getdate()) + ' ' + @UserId
WHERE Folder.FolderRSN = @FolderRSN
END


IF @AttemptResult = 5019 /*No Violations Found*/
BEGIN
UPDATE Folder
SET Folder.StatusCode = 2, Folder.FinalDate = getdate(),
Folder.FolderCondition = 'NO VIOLATIONS FOUND' + ' ' + Convert(Char(11),getdate()) + ' ' + @UserId
WHERE Folder.FolderRSN = @FolderRSN
END


IF @AttemptResult = 5018 /*Complaint Confirmed*/
BEGIN
SELECT @InspectorID = ValidUser.UserID
FROM ValidUser
WHERE ValidUser.UserName = @UserID


UPDATE Folder
SET Folder.StatusCode = 5014 /*Complaint Confirmed*/
WHERE Folder.FolderRSN = @FolderRSN

UPDATE FolderProcess
SET FolderProcess.ScheduleDate = getdate(), FolderProcess.AssignedUser = @InspectorID
WHERE FolderProcess.FolderRSN = @FolderRSN
AND FolderProcess.ProcessCode = 5004
END
GO
