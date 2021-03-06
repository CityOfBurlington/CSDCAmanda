USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_PCSW_00035130]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_PCSW_00035130]
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
/* C26 Project Decision */ 

DECLARE @AttemptResult INT
DECLARE @AttemptDate DATETIME
DECLARE @AttemptRSN INT
DECLARE @CheckProcessStatus INT
DECLARE @Debug VARCHAR(100)

SELECT @AttemptResult = ResultCode, 
@AttemptDate = AttemptDate,
@AttemptRSN = AttemptRSN
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
    (SELECT max(FolderProcessAttempt.AttemptRSN) 
     FROM FolderProcessAttempt
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

IF @AttemptResult = 35160 /* C26 Plan Approved */
BEGIN

	/* Check that Additional Information is received if its required */
	IF EXISTS (SELECT ProcessRSN FROM FolderProcess 
	  WHERE FolderProcess.FolderRSN = @FolderRSN AND ProcessCode = 35010)
	BEGIN
		SELECT @CheckProcessStatus = StatusCode FROM FolderProcess 
	  	  WHERE FolderProcess.FolderRSN = @FolderRSN AND ProcessCode = 35010
		IF @CheckProcessStatus NOT IN (35030,35055) /* Addl Info Recvd or Cancelled */
		BEGIN
			RAISERROR ('Required additional information not yet received.', 16, -1)
		END
	END

	/* Check that Site Visit is complete if its required */
	IF EXISTS (SELECT ProcessRSN FROM FolderProcess 
	  WHERE FolderProcess.FolderRSN = @FolderRSN AND ProcessCode = 35020)
	BEGIN
		SELECT @CheckProcessStatus = StatusCode FROM FolderProcess 
	  	  WHERE FolderProcess.FolderRSN = @FolderRSN AND ProcessCode = 35020
		IF @CheckProcessStatus NOT IN (35050, 35055) /* Site Visit Completed or Cancelled */
		BEGIN
			RAISERROR ('Required site visit not yet completed.', 16, -1)
		END
	END

	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 35330)
	BEGIN
		/* Set C26 Plan Approved Date Info field */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 35330 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 35330, getdate(), getdate(), getdate(), @UserID)
	END

        /* Set Process status code to C26 Plan Approved */
        UPDATE FolderProcess  
        SET StatusCode = 35160, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	/* Insert Process C26 Notify Construction Start (35060) */ 
	SELECT @NextProcessRSN = @NextProcessRSN + 1 
	INSERT INTO FolderProcess 
	       ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
	         StatusCode, PrintFlag, StampDate, StampUser, DisplayOrder ) 
	VALUES ( @NextProcessRSN, @FolderRSN, 35060, 20, 
	         1, 'Y', getdate(), @UserId, 100 ) 

	/* Set Folder Status to C26 Approved (35040) */
	UPDATE Folder SET StatusCode = 35040 WHERE FolderRSN = @FolderRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Plan Approved'

END

IF @AttemptResult = 35180 /* C26 PCSW Not Applicable */
BEGIN

	/* Set Process status code to C26 PCSW Not Applicable (35180) */
        UPDATE FolderProcess  
        SET StatusCode = 35180, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	/* Set Folder Status to C26 Not Applicable (35050) */
	UPDATE Folder SET StatusCode = 35050 WHERE FolderRSN = @FolderRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'PCSW Deemed Not Applicable'

END
GO
