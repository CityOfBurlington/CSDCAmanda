USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_EPSC_00035100]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_EPSC_00035100]
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
/* C26 Final Stabilization Inspection */ 

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

IF @AttemptResult = 35170 /* C26 Inspection Scheduled */
BEGIN

	/* Set Process status code to C26 Inspection Scheduled */
        UPDATE FolderProcess  
        SET StatusCode = 35170, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Final Stabilization Inspection Scheduled'

END

IF @AttemptResult = 35130 /* C26 Major Non-compliance */
BEGIN

	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 35170)
	BEGIN
		/* Set C26 Final Stabilization Inspection Date Info field */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 35170 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 35170, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set Process status code to C26 Major Non-compliance */
        UPDATE FolderProcess  
        SET StatusCode = 35130, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Final Stabilization Inspection Major Non-compliance'

END

IF @AttemptResult = 35140 /* C26 Minor Non-compliance */
BEGIN

	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 35170)
	BEGIN
		/* Set C26 Final Stabilization Inspection Date Info field */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 35170 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 35170, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set Process status code to C26 Minor Non-compliance */
        UPDATE FolderProcess  
        SET StatusCode = 35140, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Final Stabilization Inspection Minor Non-compliance'

END

IF @AttemptResult = 35150 /* C26 Compliance */
BEGIN

	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 35170)
	BEGIN
		/* Set C26 Final Stabilization Inspection Date Info field */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 35170 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 35170, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set Process status code to C26 Compliance */
        UPDATE FolderProcess  
        SET StatusCode = 35150, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	/* Insert Process C26 1-year Stbl Inspection (35110) */ 
	SELECT @NextProcessRSN = @NextProcessRSN + 1 
	INSERT INTO FolderProcess 
	       ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
	         StatusCode, PrintFlag, StampDate, StampUser, DisplayOrder ) 
	VALUES ( @NextProcessRSN, @FolderRSN, 35110, 75, 
	         1, 'Y', getdate(), @UserId, 150 ) 

	/* Set Folder Status to C26 Tracking (35030) */
	UPDATE Folder SET StatusCode = 35030 WHERE FolderRSN = @FolderRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Final Stabilization Inspection Compliance'

END

GO
