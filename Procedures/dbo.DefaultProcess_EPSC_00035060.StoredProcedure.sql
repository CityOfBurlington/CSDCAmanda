USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_EPSC_00035060]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_EPSC_00035060]
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
/* C26 Notify Construction Start */ 

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

IF @AttemptResult = 35110 /* C26 Notify Construction Start */
BEGIN


	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 35120)
	BEGIN
		/* Set C26 Construction Start Notification Date Info field */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 35120 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 35120, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set Process status code to C26 Notify Construction Start */
        UPDATE FolderProcess  
        SET StatusCode = 35170, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	/* Insert Process C26 Final Stbl Inspection (35100) */ 
	SELECT @NextProcessRSN = @NextProcessRSN + 1 
	INSERT INTO FolderProcess 
	       ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
	         StatusCode, PrintFlag, StampDate, StampUser, DisplayOrder ) 
	VALUES ( @NextProcessRSN, @FolderRSN, 35100, 75, 
	         1, 'Y', getdate(), @UserId, 140 ) 

	/* Set Folder Status to C26 Active (35020) */
	UPDATE Folder SET StatusCode = 35020 WHERE FolderRSN = @FolderRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Notify Construction Start'

END

GO
