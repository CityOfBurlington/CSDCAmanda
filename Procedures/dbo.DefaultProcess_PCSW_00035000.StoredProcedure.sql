USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_PCSW_00035000]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_PCSW_00035000]
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
/* C26 Application */ 

DECLARE @AttemptResult INT
DECLARE @AttemptDate DATETIME
DECLARE @AttemptRSN INT
DECLARE @Debug VARCHAR(50)

SELECT @AttemptResult = ResultCode, 
@AttemptDate = AttemptDate,
@AttemptRSN = AttemptRSN
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
    (SELECT max(FolderProcessAttempt.AttemptRSN) 
     FROM FolderProcessAttempt
     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

--SET @Debug = CONVERT(VARCHAR(10), @AttemptRSN) + ' ' + CONVERT(VARCHAR(10),@ProcessRSN) + ' ' + CONVERT(VARCHAR(10),@AttemptResult)
--RAISERROR (@Debug, 16, -1)

IF @AttemptResult = 35000 /* C26 Application Received */
BEGIN

	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 35290)
	BEGIN
		/* Set C26 Application Received Date Info field */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 35290 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 35290, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set Process status code to C26 Application Received */
        UPDATE FolderProcess  
        SET StatusCode = 35000, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Application Received'

END

IF @AttemptResult = 35005 /* C26 Application Incomplete */
BEGIN

	/* Set Process status code to C26 Application Incomplete */
        UPDATE FolderProcess  
        SET StatusCode = 35005, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Application Incomplete'

END

IF @AttemptResult = 35010 /* C26 Application Complete */
BEGIN

	IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 35300)
	BEGIN
		/* Set C26 Application Complete Date Info field */
		UPDATE FolderInfo
		SET InfoValue = getdate(), InfoValueDateTime = getdate()
		WHERE infocode = 35300 AND FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, 
			InfoValueDateTime, StampDate, StampUser)
		VALUES(@FolderRSN, 35300, getdate(), getdate(), getdate(), @UserID)
	END

	/* Set Process status code to C26 Application Complete */
        UPDATE FolderProcess  
        SET StatusCode = 35010, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	/* Insert Process C26 Project Decision (35130) */
	SELECT @NextProcessRSN = @NextProcessRSN + 1 
	INSERT INTO FolderProcess 
	       ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
	         StatusCode, PrintFlag, StampDate, StampUser, DisplayOrder ) 
	VALUES ( @NextProcessRSN, @FolderRSN, 35130, 20, 
	         1, 'Y', getdate(), @UserId, 60) 

	/* Set Folder Status to C26 Review (35010) */
	UPDATE Folder SET StatusCode = 35010 WHERE FolderRSN = @FolderRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Application Complete'

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
