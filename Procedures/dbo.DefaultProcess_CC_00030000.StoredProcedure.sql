USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_CC_00030000]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_CC_00030000]
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

SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

IF @AttemptResult = 120 /*Cancel Permit*/
BEGIN

UPDATE Folder
SET StatusCode = 30005, FinalDate = getdate()
WHERE Folder.FolderRSN = @FolderRSN

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
