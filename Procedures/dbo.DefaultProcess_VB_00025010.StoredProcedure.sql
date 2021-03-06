USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_VB_00025010]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_VB_00025010]
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
/* VB Application */

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

/*VB Application Received*/
IF @AttemptResult = 25020 
BEGIN

	/* Set Application Received Date Info field */
	UPDATE FolderInfo
	  SET InfoValue = getdate(),
		  InfoValueDateTime = getdate()
	  WHERE infocode = 25000
	  AND FolderRSN = @FolderRSN

        UPDATE FolderProcess  /* re-open this process */
        SET StatusCode = 1, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Application Received'

END


IF @AttemptResult = 25030 /*VB Application Incomplete*/
BEGIN

        UPDATE FolderProcess  /* re-open this process */
        SET StatusCode = 1, StartDate = NULL, EndDate = NULL
        WHERE FolderProcess.ProcessRSN = @ProcessRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Application Incomplete'

END


IF @AttemptResult = 25040 /*VB Application Complete*/
BEGIN

	/* Set Application Complete Date Info field */
	UPDATE FolderInfo
	  SET InfoValue = getdate(),
          InfoValueDateTime = getdate()
	  WHERE infocode = 25010
	  AND FolderRSN = @FolderRSN

	EXEC usp_UpdateFolderCondition @FolderRSN, 'Application Complete'

END

GO
