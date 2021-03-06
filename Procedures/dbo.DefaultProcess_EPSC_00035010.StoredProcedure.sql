USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_EPSC_00035010]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_EPSC_00035010]
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
/* C26 Additional Information */ 

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

IF @AttemptResult = 35020 /* C26 Application Requested */
BEGIN

	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 35310)
	BEGIN
		/* Set C26 Additional Information Requested Date Info field */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 35310 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 35310, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set Process status code to C26 Additional Information Requested */
        UPDATE FolderProcess  
        SET StatusCode = 35020, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Addl Info Requested'

END

IF @AttemptResult = 35030 /* C26 Additional Information Received */
BEGIN

	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 35320)
	BEGIN
		/* Set C26 Additional Information Received Date Info field */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 35320 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 35320, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set Process status code to C26 Additional Information Received */
        UPDATE FolderProcess  
        SET StatusCode = 35030, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Addl Info Received'

END

GO
