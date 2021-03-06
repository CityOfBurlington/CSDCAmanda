USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_AL_00030018]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_AL_00030018]
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
DECLARE @attemptCk int

SELECT @AttemptResult = Resultcode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
(SELECT MAX(FolderProcessAttempt.AttemptRSN)
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

IF @AttemptResult = 70 /*Stop Work Order*/
BEGIN

     SELECT @attemptCk = Count(*)
     FROM FolderProcessattempt
     WHERE FolderProcessattempt.ProcessRSN = @ProcessRSN
     AND FolderProcessattempt.Resultcode = 125

     IF @attemptCk <1

     BEGIN
     ROLLBACK TRANSACTION
     RAISERROR('You must issue an Order to Comply prior to issuing a Stop Work Order',16,-1)
     RETURN
     END

     ELSE

     BEGIN
     UPDATE Folder
     SET Folder.StatusCode = 30007 /*Stop Work Order*/
     WHERE Folder.FolderRSN = @FolderRSN
     OR Folder.ParentRSN = @FolderRSN
     AND Folder.StatusCode NOT IN (2, 30005, 30003, 30004, 30006)

     UPDATE FolderProcess /*reopen this process*/
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1
     WHERE FolderProcess.processRSN = @processRSN
     
     END
END

IF @AttemptResult = 130 /*Stop Work Order Lifted*/
BEGIN

     UPDATE Folder
     SET Folder.StatusCode = 30002 /*Issued*/
     WHERE Folder.FolderRSN = @FolderRSN
     OR Folder.ParentRSN = @FolderRSN
     AND Folder.StatusCode = 30002

     UPDATE FolderProcess /*reopen this process*/
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1
     WHERE FolderProcess.processRSN = @processRSN

END

IF @AttemptResult = 35 /*Legal Action*/
BEGIN

     UPDATE Folder
     SET Folder.StatusCode = 30008 /*Legal Action*/
     WHERE Folder.FolderRSN = @FolderRSN
     OR Folder.ParentRSN = @FolderRSN
     AND Folder.StatusCode NOT IN (2, 30005, 30003, 30004, 30006)

     UPDATE FolderProcess /*reopen this process*/
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1
     WHERE FolderProcess.processRSN = @processRSN

END

IF @AttemptResult = 135 /*Legal Action Resolved*/
BEGIN

     UPDATE Folder
     SET Folder.StatusCode = 30002 /*Issued*/
     WHERE Folder.FolderRSN = @FolderRSN
     OR Folder.ParentRSN = @FolderRSN
     AND Folder.StatusCode = 30008

     UPDATE FolderProcess /*reopen this process*/
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1
     WHERE FolderProcess.processRSN = @processRSN

END

IF @AttemptResult = 20 /*Not Required*/
BEGIN
    UPDATE FolderProcess
    SET ProcessComment = 'Not Required'
    WHERE FolderProcess.processRSN = @processRSN

END
GO
