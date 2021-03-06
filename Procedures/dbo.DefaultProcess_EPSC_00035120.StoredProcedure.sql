USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_EPSC_00035120]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_EPSC_00035120]
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
/* C26 Plan Approved */ 

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

	/* Check that Tech Meeting is complete if its required */
	IF EXISTS (SELECT ProcessRSN FROM FolderProcess 
	  WHERE FolderProcess.FolderRSN = @FolderRSN AND ProcessCode = 35030)
	BEGIN
		SELECT @CheckProcessStatus = StatusCode FROM FolderProcess 
	  	  WHERE FolderProcess.FolderRSN = @FolderRSN AND ProcessCode = 35030
		IF @CheckProcessStatus NOT IN (35070, 35055) /* Tech Meeting Completed or Cancelled */
		BEGIN
			RAISERROR ('Required tech meeting not yet completed.', 16, -1)
		END
	END

	/* Check that Pre-construction Meeting is complete if its required */
	--IF EXISTS (SELECT ProcessRSN FROM FolderProcess 
	--  WHERE FolderProcess.FolderRSN = @FolderRSN AND ProcessCode = 35040)
	--BEGIN
	--	SELECT @CheckProcessStatus = StatusCode FROM FolderProcess 
	--  	  WHERE FolderProcess.FolderRSN = @FolderRSN AND ProcessCode = 35040
	--	IF @CheckProcessStatus NOT IN (35090, 35055) /* Pre-construction Meeting Completed or Cancelled */
	--	BEGIN
	--		RAISERROR ('Required pre-construction meeting not yet completed.', 16, -1)
	--	END
	--END

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



GO
