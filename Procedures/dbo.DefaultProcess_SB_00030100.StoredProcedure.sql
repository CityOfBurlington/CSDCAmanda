USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_SB_00030100]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_SB_00030100]
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


IF @AttemptResult = 60 /*Cancelled*/
BEGIN
UPDATE
Folder
SET Folder.StatusCode = 2 /*Closed*/, Folder.Finaldate = getdate(),ExpiryDate = NULL,
Folder.FolderDescription = CAST(Folder.FolderDescription AS VARCHAR(4000)) + 'Permit Cancelled', issuedate = NULL, issueuser = NULL
WHERE 
Folder.FolderRSN = @FolderRSN
END



IF @AttemptResult = 105 /*Denied */
BEGIN
UPDATE 
Folder
SET Folder.StatusCode = 65 /*Denied*/, Folder.ExpiryDate = getdate()+10
WHERE 
Folder.FolderRSN = @FolderRSN

UPDATE
FolderProcess
SET StatusCode = 1, EndDate = Null, ScheduleDate = getdate()+15
WHERE FolderProcess.FolderRSN = @FolderRSN
AND FolderProcess.ProcessRSN = @ProcessRSN
END


IF @AttemptResult = 30107 /*Appeal  Denial*/
BEGIN
UPDATE
Folder
SET Folder.StatusCode = 200
WHERE 
Folder.FolderRSN = @FolderRSN

UPDATE
FolderProcess
SET FolderProcess.StatusCode = 1, FolderProcess.ScheduleDate = getdate()
WHERE FolderProcess.FolderRSN = @FolderRSN
AND FolderProcess.ProcessRSN = @ProcessRSN
END

GO
