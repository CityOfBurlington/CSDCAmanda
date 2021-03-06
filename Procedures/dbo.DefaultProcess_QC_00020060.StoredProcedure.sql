USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QC_00020060]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QC_00020060]
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
DECLARE @AttemptResult INT

SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)


IF @AttemptResult IN(30120 /*Zoning File Reviewed*/, 30125 /*Assign Field Inspection*/, 30130 /*Zoning Docs Attached*/)
    BEGIN

    SELECT @NextProcessRSN = MAX(ProcessRSN) + 1 FROM FolderProcess 

    INSERT INTO FolderProcess
    (ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
    PrintFlag, StatusCode, StampDate, StampUser, AssignedUser) 
    VALUES ( @NextProcessRSN, @FolderRSN, 20030, 90, 
    'Y', 1, GetDate(), @UserId, @UserId) 
END
GO
