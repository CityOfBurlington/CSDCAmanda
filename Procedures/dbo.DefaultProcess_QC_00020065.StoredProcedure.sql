USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QC_00020065]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QC_00020065]
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
DECLARE @AttachmentCount INT
DECLARE @AttemptResult INT

SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @AttachmentCount = SUM(1)
FROM Attachment
WHERE TableRSN = @FolderRSN
AND TableName = 'Folder'

SET @AttachmentCount = ISNULL(@AttachmentCount, 0)

IF @AttachmentCount > 0 
    BEGIN

    SELECT @NextProcessRSN = MAX(ProcessRSN) + 1 FROM FolderProcess 

    INSERT INTO FolderProcess
    (ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
    PrintFlag, StatusCode, StampDate, StampUser, AssignedUser) 
    VALUES ( @NextProcessRSN, @FolderRSN, 20070, 90, 
    'Y', 1, GetDate(), @UserId, @UserId) 
    END
ELSE
    BEGIN

    RAISERROR('There should be at least one item or photo in the Attachment tab', 16, -1)
END
GO
