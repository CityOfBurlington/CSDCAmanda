USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_EPSC_00035020]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_EPSC_00035020]
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
/* C26 Site Visit */ 

DECLARE @AttemptResult INT
DECLARE @AttemptDate DATETIME
DECLARE @AttemptRSN INT

SELECT @AttemptResult = ResultCode, 
@AttemptDate = AttemptDate,
@AttemptRSN = AttemptRSN
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
    (SELECT max(FolderProcessAttempt.AttemptRSN) 
     FROM FolderProcessAttempt
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

IF @AttemptResult = 35040 /* C26 Site Visit Scheduled */
BEGIN

	/* Set Process status code to C26 Site Visit Scheduled */
        UPDATE FolderProcess  
        SET StatusCode = 35040, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Site Visit Scheduled'

END

IF @AttemptResult = 35050 /* C26 Site Visit Completed */
BEGIN

	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 35090)
	BEGIN
		/* Set C26 Site Visit Completed Date Info field */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 35090 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 35090, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set Process status code to C26 Site Visit Completed */
        UPDATE FolderProcess  
        SET StatusCode = 35050, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Site Visit Completed'

END

IF @AttemptResult = 35055 /* C26 Cancelled */
BEGIN

	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 35090)
	BEGIN
		/* Set C26 Additional Information Received Date Info field */
		UPDATE FolderInfo
		SET InfoValue = NULL, InfoValueDateTime = NULL
		WHERE infocode = 35090 AND FolderRSN = @FolderRSN
	END

	/* Set Process status code to Cancelled */
        UPDATE FolderProcess  
        SET StatusCode = 35055, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Addl Site Visit Cancelled'

END
GO
