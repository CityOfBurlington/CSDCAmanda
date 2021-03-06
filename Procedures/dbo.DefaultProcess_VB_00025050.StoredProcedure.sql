USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_VB_00025050]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_VB_00025050]
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

/* No Longer Vacant, VB Process */ 

DECLARE @AttemptDate DATETIME

SELECT @AttemptDate = FolderProcessAttempt.AttemptDate FROM FolderProcessAttempt 
WHERE FolderRSN = @FolderRSN AND ProcessRSN = @ProcessRSN AND 
AttemptRSN = (SELECT MAX(AttemptRSN) FROM FolderProcessAttempt WHERE ProcessRSN = @ProcessRSN)

    /* Set Folder Status to Closed (2) */
    UPDATE Folder SET StatusCode = 2 WHERE FolderRSN = @FolderRSN

    EXEC usp_UpdateFolderCondition @FolderRSN, 'VB No Longer Vacant'

    IF EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 25080)
    BEGIN
        UPDATE FolderInfo SET InfoValue = @AttemptDate, InfoValueDateTime = @AttemptDate WHERE FolderRSN = @FolderRSN AND InfoCode = 25080
    END
    ELSE
    BEGIN
        INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, InfoValueDateTime, StampDate, StampUser, Mandatory, ValueRequired)
        VALUES(@FolderRSN, 25080, @AttemptDate, @AttemptDate, GetDate(), @UserId, 'N', 'N')
    END


GO
