USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_OB_00030013]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_OB_00030013]
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
DECLARE @AttemptResult int
DECLARE @ExpirationDate datetime

SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @ExpirationDate = Folder.ExpiryDate
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN


IF @AttemptResult = 145 /*Obstruction Removed*/
BEGIN
     UPDATE Folder
     SET Folder.StatusCode = 2, Folder.FinalDate = getdate()
     WHERE Folder.FolderRSN = @FolderRSN

     UPDATE FolderProcess  /*close any open processes*/
     SET FolderProcess.EndDate = getdate(), FolderProcess.StatusCode = 2
     WHERE FolderProcess.FolderRSN = @FolderRSN
     AND FolderProcess.EndDate IS NULL
END


IF @AttemptResult = 155 /*Enforce Removal*/
BEGIN
     UPDATE Folder
     SET StatusCode = 2, FinalDate = getdate()
     WHERE Folder.FolderRSN = @FolderRSN

     UPDATE FolderProcess  /*close any open processes*/
     SET FolderProcess.EndDate = getdate(), FolderProcess.StatusCode = 2
     WHERE FolderProcess.FolderRSN = @FolderRSN
     AND FolderProcess.EndDate IS NULL
END

IF @AttemptResult = 160 /*Past Expiration*/
BEGIN
    UPDATE Folder
    SET StatusCode = 30009 /*In Violation*/
    WHERE Folder.FolderRSN = @FolderRSN
    
    UPDATE FolderProcess
    SET ScheduleDate = getdate(), EndDate=Null, StatusCode = 1
    WHERE FolderProcess.processRSN = @processRSN
END

IF @AttemptResult = 165 /*Council Approval*/
BEGIN
    UPDATE Folder
    SET StatusCode = 30010 /*Extended By Council*/,finaldate = getdate()
    WHERE Folder.FolderRSN = @FolderRSN
     
END


IF @AttemptResult = 150 /*Obstruction in Place*/
BEGIN
    UPDATE FolderProcess
    SET ScheduleDate = @Expirationdate, EndDate=Null, StatusCode = 1
    WHERE FolderProcess.processRSN = @processRSN

END

IF @attemptresult = 175 /*Legal Action*/
   BEGIN
   UPDATE Folder
   SET StatusCode = 30008 /*Legal Action*/
   WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderProcess
   SET StatusCode = 1, EndDate = Null
   WHERE FolderProcess.ProcessRSN = @ProcessRSN
END

IF @attemptresult = 180 /*Legal Action Resolved*/
   BEGIN
   UPDATE Folder
   SET StatusCode = 30002 /*Issued*/
   WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderProcess
   SET StatusCode = 1, EndDate = Null
   WHERE FolderProcess.ProcessRSN = @ProcessRSN
END

IF @AttemptResult = 60 /*canceled*/
BEGIN
    UPDATE Folder
    SET Folder.StatusCode = 30005, FinalDate = GetDate()
    WHERE Folder.FolderRSN = @FolderRSN

    UPDATE FolderProcess /*add a comment*/
    SET Enddate=getdate(), StatusCode = 2, ProcessComment = 'Process canceled'
    WHERE FolderProcess.processRSN = @processRSN
END

GO
