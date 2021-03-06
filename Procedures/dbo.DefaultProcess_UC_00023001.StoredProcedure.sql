USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_UC_00023001]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_UC_00023001]
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
   
/* Setup Info (23001) version 1 */

/* Adds or deletes Permit FolderRSN Info fields - 20 total. An additional 
   Permit FolderRSN Info field will be added only if all the ones present are 
   not null. Info fields are inserted in ascending order by InfoCode. */

/* Sets up Info fields and process for Temporary UCOs. */ 

DECLARE @AttemptResult int
DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @FolderCondition varchar(2000)
DECLARE @InfoPermitFolderRSNOrder int
DECLARE @InfoPermitFolderRSNNextOrder int
DECLARE @NullPermitFolderRSN int
DECLARE @InfoCodeExists int
DECLARE @ExpectedInfoCode int
DECLARE @NextInfoCode int
DECLARE @ProcessNote varchar(50)
DECLARE @TCOTermInfoCode int
DECLARE @TCODecisionDateInfoCode int
DECLARE @TCOExpiryDateInfoCode int
DECLARE @TCOConditionsDateInfoCode int
DECLARE @TCOTermInfoOrder int
DECLARE @TCODecisionDateInfoOrder int
DECLARE @TCOExpiryDateInfoOrder int
DECLARE @TCOConditionsDateInfoOrder int
DECLARE @TCOProcess int
DECLARE @OccupancyLoadInfoCode int
DECLARE @OccupancyLoadInfoOrder int

/* Get Attempt Result */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
	( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
	  FROM FolderProcessAttempt
	  WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

SELECT @FolderStatus = Folder.StatusCode, @InDate = Folder.InDate, 
	   @SubCode = Folder.SubCode, @WorkCode = Folder.WorkCode,
	   @FolderCondition = Folder.FolderCondition
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

SELECT @NullPermitFolderRSN = COUNT(*)
FROM FolderInfo
WHERE FolderInfo.InfoCode BETWEEN 23001 AND 23020
AND FolderInfo.InfoValueNumeric = 0 
AND FolderInfo.FolderRSN = @FolderRSN

SELECT @ExpectedInfoCode = 23001
SELECT @NextInfoCode = 0

WHILE @ExpectedInfoCode < 23021
BEGIN
	SELECT @InfoCodeExists = COUNT(*)
	FROM FolderInfo
	WHERE FolderInfo.InfoCode = @ExpectedInfoCode
	AND FolderInfo.FolderRSN = @FolderRSN

	IF @InfoCodeExists = 0 
	BEGIN
		SELECT @NextInfoCode = @ExpectedInfoCode
		SELECT @InfoPermitFolderRSNNextOrder = ( @ExpectedInfoCode - 23000 ) * 10 
		BREAK
	END
	ELSE SELECT @ExpectedInfoCode = @ExpectedInfoCode + 1
END

/* Add Permit Link attempt result. Runs only if there are no Permit FolderRSN 
   Info fields that are not null.  Set Folder Status to UCO In Process. 
   Folder.SubCode and Folder.WorkCode are nulled out in order to force use of 
   Permit Status Report. */

IF @AttemptResult = 23001 
BEGIN
	IF @NullPermitFolderRSN = 0
	BEGIN
		INSERT INTO FolderInfo
				( FolderRSN, InfoCode, DisplayOrder, PrintFlag, InfoValue, InfoValueNumeric,
				  StampDate, StampUser, Mandatory, ValueRequired )
		VALUES ( @FolderRSN, @NextInfoCode,  @InfoPermitFolderRSNNextOrder, 'Y', NULL, 0, 
				 getdate(), @UserID, 'N', 'N' )

		UPDATE Folder
		SET Folder.StatusCode = 23002, Folder.SubCode = NULL, Folder.WorkCode = NULL
		WHERE Folder.FolderRSN = @FolderRSN

		IF @FolderCondition IS NULL
		BEGIN
			UPDATE Folder
			SET Folder.FolderCondition = 'UCO Request Received (' + CONVERT(CHAR(11), @InDate) + ')'
			WHERE Folder.FolderRSN = @FolderRSN
		END

		SELECT @ProcessNote = 'Info field ' + RTRIM(CAST(@NextInfoCode AS CHAR)) + ' added'
	END
	ELSE SELECT @ProcessNote = 'Info field not added because one is available'
END

/* Remove Permit Link attempt result.  Deletes all Permit FolderRSN Info fields that InfoValueNumeric = 0. 
   At insertion, InfoValueNumeric is set to zero. */

IF @AttemptResult = 23002
BEGIN
	DELETE FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @FolderRSN
	AND FolderInfo.InfoCode BETWEEN 23001 AND 23020 
	AND FolderInfo.InfoValueNumeric = 0

	SELECT @ProcessNote = RTRIM(CAST(@NullPermitFolderRSN AS CHAR)) + ' unused Info field(s) deleted'

	UPDATE Folder
	SET Folder.SubCode = NULL, Folder.WorkCode = NULL
	WHERE Folder.FolderRSN = @FolderRSN
END

/* Setup TCO Info fields and add TCO process. The Permit Status Check process must 
   have been run and WorkCode set to Building Ready (23001).  */

IF @AttemptResult = 23006
BEGIN
	SELECT @ProcessNote = 'Setup for TCO'

	SELECT @TCOTermInfoCode = COUNT(*)
	FROM FolderInfo
	WHERE FolderInfo.InfoCode = 23031
	AND FolderInfo.FolderRSN = @FolderRSN

	SELECT @TCODecisionDateInfoCode = COUNT(*)
	FROM FolderInfo
	WHERE FolderInfo.InfoCode = 23032
	AND FolderInfo.FolderRSN = @FolderRSN

	SELECT @TCOExpiryDateInfoCode = COUNT(*)
	FROM FolderInfo
	WHERE FolderInfo.InfoCode = 23033
	AND FolderInfo.FolderRSN = @FolderRSN

	SELECT @TCOConditionsDateInfoCode = COUNT(*)
	FROM FolderInfo
	WHERE FolderInfo.InfoCode = 23034
	AND FolderInfo.FolderRSN = @FolderRSN

	SELECT @OccupancyLoadInfoCode = COUNT(*)
	FROM FolderInfo 
	WHERE FolderInfo.InfoCode = 23030 
	AND FolderInfo.FolderRSN = @FolderRSN

	IF @OccupancyLoadInfoCode = 0 SELECT @OccupancyLoadInfoOrder = 310
	ELSE
	BEGIN
		SELECT @OccupancyLoadInfoOrder = ISNULL(FolderInfo.DisplayOrder, 310)
		FROM FolderInfo 
		WHERE FolderInfo.InfoCode = 23030 
		AND FolderInfo.FolderRSN = @FolderRSN
	END

	SELECT @TCOConditionsDateInfoOrder = @OccupancyLoadInfoOrder + 10
	SELECT @TCOTermInfoOrder = @OccupancyLoadInfoOrder + 20
	SELECT @TCODecisionDateInfoOrder = @OccupancyLoadInfoOrder + 30
	SELECT @TCOExpiryDateInfoOrder = @OccupancyLoadInfoOrder + 40

	IF @TCOConditionsDateInfoCode = 0
	BEGIN
		INSERT INTO FolderInfo
			( FolderRSN, InfoCode, DisplayOrder, PrintFlag, StampDate, StampUser, Mandatory, ValueRequired )
		VALUES ( @FolderRSN, 23034,  @TCOConditionsDateInfoOrder, 'Y', getdate(), @UserID, 'N', 'N' )
	END

	IF @TCOTermInfoCode = 0
	BEGIN
	INSERT INTO FolderInfo
		( FolderRSN, InfoCode, DisplayOrder, PrintFlag, InfoValueNumeric,StampDate, StampUser, Mandatory, ValueRequired )
	VALUES ( @FolderRSN, 23031,  @TCOTermInfoOrder, 'Y', 0, getdate(), @UserID, 'N', 'N' )
   END

	IF @TCODecisionDateInfoCode = 0
	BEGIN
		INSERT INTO FolderInfo
			( FolderRSN, InfoCode, DisplayOrder, PrintFlag, StampDate, StampUser, Mandatory, ValueRequired )
		VALUES ( @FolderRSN, 23032,  @TCODecisionDateInfoOrder, 'Y', getdate(), @UserID, 'N', 'N' )
	END

	IF @TCOExpiryDateInfoCode = 0
	BEGIN
		INSERT INTO FolderInfo
			( FolderRSN, InfoCode, DisplayOrder, PrintFlag, StampDate, StampUser, Mandatory, ValueRequired )
		VALUES ( @FolderRSN, 23033,  @TCOExpiryDateInfoOrder, 'Y', getdate(), @UserID, 'N', 'N' )
	END

	SELECT @TCOProcess = COUNT(*)
	FROM FolderProcess
	WHERE FolderProcess.FolderRSN = @FolderRSN
	AND FolderProcess.ProcessCode = 23004

	IF @TCOProcess = 0
	BEGIN
		SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
		FROM FolderProcess

		INSERT INTO FolderProcess
			( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode, ScheduleDate, DisplayOrder,
			  PrintFlag, MandatoryFlag, StampDate, StampUser )
		VALUES ( @NextProcessRSN, @folderRSN, 23004, 90, 1,getdate(), 400, 
				 'Y', 'Y', getdate(), @UserID )
	END
	ELSE
	BEGIN
		UPDATE FolderProcess
		SET FolderProcess.StatusCode = 1, 
			FolderProcess.ScheduleDate = getdate(),
			FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
			FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL 
		WHERE FolderProcess.ProcessCode = 23004
		AND FolderProcess.FolderRSN = @folderRSN
	END
END

/* Pull the plug on the entire UCO, and close all processes. */

IF @AttemptResult = 23005    /* Withdraw UCO Request */
BEGIN
	UPDATE Folder
	SET Folder.IssueDate = NULL, Folder.ExpiryDate = NULL, 
		Folder.FinalDate = getdate(), Folder.StatusCode = 23006, 
		Folder.FolderCondition = 
			CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000),FolderCondition)) + 
			' -> UCO Request Withdrawn (' + CONVERT(CHAR(11), getdate()) + ')' ))
	FROM Folder
	WHERE Folder.FolderRSN = @FolderRSN

	UPDATE FolderProcess
	SET FolderProcess.ProcessComment = 'UCO Withdrawn',
		FolderProcess.StartDate = @InDate, FolderProcess.EndDate = getdate(), 
		FolderProcess.SignOffUser = @UserID
	WHERE FolderProcess.FolderRSN = @FolderRSN
	AND FolderProcess.ProcessRSN = @ProcessRSN

	UPDATE FolderProcessAttempt
	SET FolderProcessAttempt.AttemptComment = 'Withdrawn (' + CONVERT(char(11), getdate()) + ')', 
		FolderProcessAttempt.AttemptBy = @UserID
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
	AND FolderProcessAttempt.AttemptRSN = 
		( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
		  FROM FolderProcessAttempt
		  WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

	UPDATE FolderProcess
	SET FolderProcess.StatusCode = 2, FolderProcess.SignOffUser = @UserID
	WHERE FolderProcess.StatusCode = 1
	AND FolderProcess.ProcessCode IN (23001, 23002, 23003, 23004)
	AND FolderProcess.FolderRSN = @FolderRSN
END

/* Document attempt result and reopen process, except for Withdraw UCO Request */

IF @AttemptResult <> 23005 
BEGIN
	UPDATE FolderProcessAttempt
	SET FolderProcessAttempt.AttemptComment = @ProcessNote, 
		FolderProcessAttempt.AttemptBy = @UserID
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
	AND FolderProcessAttempt.AttemptRSN = 
		( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
		  FROM FolderProcessAttempt
		  WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

	UPDATE FolderProcess
	SET FolderProcess.StatusCode = 1, 
		FolderProcess.ScheduleDate = getdate(),
		FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
		FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL 
	WHERE FolderProcess.ProcessRSN = @ProcessRSN
	AND FolderProcess.FolderRSN = @FolderRSN
END

GO
