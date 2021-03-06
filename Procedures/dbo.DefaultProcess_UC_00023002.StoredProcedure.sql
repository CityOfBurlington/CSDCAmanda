USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_UC_00023002]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_UC_00023002]
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

/* Permit Status Check (23002 - Version 3) */

/* Checks status of linked permit folders and records result in Sub and Work fields.  
   When all have their individual CO's, the folder status becomes UCO Pending and 
   the Unified Cerificate of Occupancy process is added. */

/* Version 2 takes into account Phased CO issuance (Feb 7, 2013).  */

/* Version 3 enables TCO issuance (Feb 15, 2013). */

DECLARE @intNullInfoFieldFlag int
DECLARE @intInfoFieldCount int
DECLARE @intZPFolderCount int
DECLARE @intZPFolderUCOReadyCount int
DECLARE @intZPFolderTCOReadyCount int
DECLARE @intBPFolderCount int
DECLARE @intBPFolderReadyCount int
DECLARE @intPermitFolderRSN int
DECLARE @varPermitFolderType varchar(4)
DECLARE @intPermitFolderStatus int
DECLARE @varPermitNumber varchar(20)
DECLARE @intSubCode int
DECLARE @intWorkCode int
DECLARE @intCounter int
DECLARE @varZPUCOReadyFlag varchar(1)
DECLARE @varZPTCOReadyFlag varchar(1)
DECLARE @varBPReadyFlag varchar(1)
DECLARE @varProcessNote varchar(50)
DECLARE @varProcessAttemptNote varchar(50)
DECLARE @varErrorMessage varchar(200)
DECLARE @intUCOStatusCode int 
DECLARE @dtUCOInDate datetime
DECLARE @varUCOFolderCondition varchar(2000)
DECLARE @intUCOPhaseNumberCount int
DECLARE @intUCOPhaseNumberValue int
DECLARE @intPCOProcessCount int
DECLARE @intPCOProcessRSN int
DECLARE @intPCOProcessStatusCode int 
DECLARE @intPCOProcessAttemptResultCount int
DECLARE @intPCOProcessLastAttemptResult int
DECLARE @varPCOProcessComment varchar(2000)
DECLARE @intPCOProcessStatus int
DECLARE @intCOProcessAttemptResultCount int
DECLARE @intCOProcessRSN int
DECLARE @intCOProcessLastAttemptResult int
DECLARE @varPhasingFlag varchar(2)
DECLARE @intFirstPermitFolderRSN int
DECLARE @varFirstPermitNumber varchar(15)
DECLARE @varFirstFolderDescription varchar(500)

SELECT @intNullInfoFieldFlag = COUNT(*)
  FROM FolderInfo
 WHERE FolderInfo.InfoValue IS NULL 
   AND FolderInfo.InfoCode BETWEEN 23001 AND 23020
   AND FolderInfo.FolderRSN = @FolderRSN

IF @intNullInfoFieldFlag > 0
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Null Permit FolderRSN Info fields exist. Remove them using Setup Info. Exitting.', 16, -1)
   RETURN
END

SELECT @intInfoFieldCount = COUNT(*)
  FROM FolderInfo
 WHERE FolderInfo.InfoCode BETWEEN 23001 AND 23020
   AND FolderInfo.FolderRSN = @FolderRSN

IF @intInfoFieldCount = 0
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Permit FolderRSN Info fields are required. Add them using Setup Info and code. Exitting.', 16, -1)
   RETURN
END

SELECT @intUCOPhaseNumberCount = COUNT(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 23035

IF @intUCOPhaseNumberCount > 0
BEGIN
	SELECT @intUCOPhaseNumberValue = ISNULL(FolderInfo.InfoValueNumeric, 0)
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @FolderRSN
	AND FolderInfo.InfoCode = 23035
END
ELSE SELECT @intUCOPhaseNumberValue = 0 

IF @intUCOPhaseNumberCount > 0 AND @intUCOPhaseNumberValue = 0 
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter a Construction Phase Number under Info to continue. Exitting.', 16, -1)
   RETURN
END

/* All Info field ducks are now in a row - all linked folders are eligible for CO's */

SELECT @intZPFolderCount = 0 
SELECT @intBPFolderCount = 0 
SELECT @intZPFolderUCOReadyCount = 0
SELECT @intZPFolderTCOReadyCount = 0
SELECT @intBPFolderReadyCount = 0
SELECT @intSubCode = 23003
SELECT @intWorkCode = 23003
SELECT @varZPUCOReadyFlag = 'Y'
SELECT @varZPTCOReadyFlag= 'N'
SELECT @varBPReadyFlag = 'Y'

SELECT @intCounter = 1

WHILE @intCounter < ( @intInfoFieldCount + 1 ) 
BEGIN
	SELECT @intPermitFolderRSN = FolderInfo.InfoValueNumeric
	FROM FolderInfo
	WHERE FolderInfo.InfoCode = ( 23000 + @intCounter )
	AND FolderInfo.FolderRSN = @FolderRSN

	SELECT @varPermitFolderType = Folder.FolderType, @intPermitFolderStatus = Folder.StatusCode, 
		   @varPermitNumber = Folder.ReferenceFile
	FROM Folder
	WHERE Folder.FolderRSN = @intPermitFolderRSN

	IF @varPermitFolderType LIKE 'Z%'        /* Zoning folders */
	BEGIN
		SELECT @intPCOProcessRSN = dbo.udf_GetUCOPhasePermitProcessRSN(@intPermitFolderRSN, @intUCOPhaseNumberValue) 

		IF @intPCOProcessRSN > 0       /* Project Phasing */
		BEGIN
		 /* IF @intPCOProcessRSN = 0     ZP and UCO Phase Numbers do not match -> can't figure out how to catch this error 
			BEGIN
				SELECT @varErrorMessage = 'The UCO Construction Phase Number ' + RTRIM(CAST(@intUCOPhaseNumberValue AS CHAR)) + ' does not have a match in the Zoning folder. Please set to a valid Phase Number.'
				ROLLBACK TRANSACTION
				RAISERROR (@varErrorMessage, 16, -1)
				RETURN
			END */
			
			SELECT @intPCOProcessAttemptResultCount = COUNT(*)
			FROM FolderProcessAttempt
			WHERE FolderProcessAttempt.ProcessRSN = @intPCOProcessRSN

			IF @intPCOProcessAttemptResultCount > 0
			BEGIN
				SELECT @intPCOProcessLastAttemptResult = FolderProcessAttempt.ResultCode 
				FROM FolderProcessAttempt
				WHERE FolderProcessAttempt.ProcessRSN = @intPCOProcessRSN
				AND FolderProcessAttempt.AttemptRSN = 
				  ( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
					FROM FolderProcessAttempt
					WHERE FolderProcessAttempt.ProcessRSN = @intPCOProcessRSN ) 
			END
			ELSE SELECT @intPCOProcessLastAttemptResult = 0

			IF @intPCOProcessLastAttemptResult = 10067    /* Abandon Phase */
			BEGIN
				SELECT @varErrorMessage = 'Construction Phase Number ' + RTRIM(CAST(@intUCOPhaseNumberValue AS CHAR)) + ' was Abandoned. Please set Construction Phase Number (Info) to a valid value.'
				ROLLBACK TRANSACTION
				RAISERROR (@varErrorMessage, 16, -1)
				RETURN
			END
			ELSE
			BEGIN
				IF @intPCOProcessLastAttemptResult <> 10066 SELECT @varZPUCOReadyFlag = 'N'
				IF @intPCOProcessStatus <> 10004 SELECT @varZPTCOReadyFlag = 'N'
			END
         			
			/* Update UCO values when the loop's current permit is the phasing permit. UCO values for 
			   Single phase projects are updated after the InfoCode loop. */  
			
			SELECT @varPCOProcessComment = FolderProcess.ProcessComment	/* Phase description text set up by Project Manager */ 
			FROM FolderProcess
			WHERE FolderProcess.ProcessRSN = @intPCOProcessRSN 

			UPDATE Folder
			SET Folder.ReferenceFile = @varPermitNumber, 
				Folder.ParentRSN = @intPermitFolderRSN, 
				Folder.FolderDescription = @varPCOProcessComment
			WHERE Folder.FolderRSN = @FolderRSN 
		END
		ELSE    /* Single Phase Projects - Status must be Final CO Issued or Review Complete */
		BEGIN
		/*	SELECT @intCOProcessAttemptResultCount = COUNT(*)
			FROM FolderProcessAttempt, FolderProcess 
			WHERE FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
			AND FolderProcess.FolderRSN = @intPermitFolderRSN
			AND FolderProcess.ProcessCode = 10001
			
			IF @intCOProcessAttemptResultCount > 0
			BEGIN
				SELECT @intCOProcessRSN = ISNULL(FolderProcess.ProcessRSN, 0)
				FROM FolderProcess
				WHERE FolderProcess.FolderRSN = @intPermitFolderRSN
				AND FolderProcess.ProcessCode = 10001
			
				SELECT @intCOProcessLastAttemptResult = FolderProcessAttempt.ResultCode 
				FROM FolderProcessAttempt
				WHERE FolderProcessAttempt.ProcessRSN = @intCOProcessRSN
				AND FolderProcessAttempt.AttemptRSN = 
				  ( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
					FROM FolderProcessAttempt
					WHERE FolderProcessAttempt.ProcessRSN = @intCOProcessRSN ) 
			END */
			
			IF @intPermitFolderStatus NOT IN (10008, 10031) SELECT @varZPUCOReadyFlag = 'N'
			
			IF @intPermitFolderStatus = 10007 /* AND @intCOProcessLastAttemptResult = 10029   -> This check not necessary */
				SELECT @varZPTCOReadyFlag = 'Y' 
		END
      
		SELECT @intZPFolderCount = @intZPFolderCount + 1
		SELECT @intSubCode = 23001
		IF @varZPUCOReadyFlag = 'Y' SELECT @intZPFolderUCOReadyCount = @intZPFolderUCOReadyCount + 1
		IF @varZPTCOReadyFlag = 'Y' SELECT @intZPFolderTCOReadyCount = @intZPFolderTCOReadyCount + 1
      
	END   /* End of zoning folders */

	IF @varPermitFolderType IN ('BP','EP','MP')          /* Construction Permits */
	BEGIN
		SELECT @intBPFolderCount = @intBPFolderCount + 1
		SELECT @intWorkCode = 23001
		IF @intPermitFolderStatus <> 2 SELECT @varBPReadyFlag = 'N'
		ELSE SELECT @intBPFolderReadyCount = @intBPFolderReadyCount + 1
	END

	SELECT @intCounter = @intCounter + 1

END  /* End of Permit FolderRSN InfoCode loop */

/* Update UC folder values for single phase projects. */

SELECT @varPhasingFlag = dbo.udf_UCOPhasingFlag(@FolderRSN)  /* Returns 'N' if any permit has Number of Phases < 2 (InfoCode 10081) */
 
IF @varPhasingFlag = 'N'	/* FirstPermitFolderRSN is based upon Folder.IssueDate. */
BEGIN
	SELECT @intFirstPermitFolderRSN  = dbo.udf_GetUCOFirstPermitFolderRSN(@FolderRSN) 
	
	SELECT @varFirstPermitNumber = Folder.ReferenceFile, 
		   @varFirstFolderDescription = Folder.FolderDescription
	FROM Folder
	WHERE Folder.FolderRSN = @intFirstPermitFolderRSN 

	UPDATE Folder 
	SET Folder.ReferenceFile = @varFirstPermitNumber, 
		Folder.ParentRSN = @intFirstPermitFolderRSN, 
		Folder.FolderDescription = @varFirstFolderDescription 
	WHERE Folder.FolderRSN = @FolderRSN 
END

/* Record results in UC folder, set status, and reopen process. */

IF @varZPUCOReadyFlag = 'N' AND @varZPTCOReadyFlag = 'N' SELECT @intSubCode  = 23002
IF @varZPUCOReadyFlag = 'N' AND @varZPTCOReadyFlag = 'Y' SELECT @intSubCode  = 23004
IF @varZPUCOReadyFlag = 'Y' SELECT @intSubCode = 23001

IF @varBPReadyFlag = 'N' SELECT @intWorkCode = 23002
IF @varBPReadyFlag = 'Y' SELECT @intWorkCode = 23001

UPDATE Folder
SET Folder.SubCode = @intSubCode, Folder.WorkCode = @intWorkCode
WHERE Folder.FolderRSN = @FolderRSN

UPDATE FolderProcessInfo
SET FolderProcessInfo.InfoValue = @intZPFolderCount, 
	FolderProcessInfo.InfoValueNumeric = @intZPFolderCount, 
	FolderProcessInfo.StampDate = getdate(), FolderProcessInfo.StampUser = @UserID
WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
AND FolderProcessInfo.InfoCode = 23001

UPDATE FolderProcessInfo
SET FolderProcessInfo.InfoValue = @intZPFolderUCOReadyCount, 
	FolderProcessInfo.InfoValueNumeric = @intZPFolderUCOReadyCount, 
	FolderProcessInfo.StampDate = getdate(), FolderProcessInfo.StampUser = @UserID
WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
AND FolderProcessInfo.InfoCode = 23002

UPDATE FolderProcessInfo
SET FolderProcessInfo.InfoValue = @intBPFolderCount, 
	FolderProcessInfo.InfoValueNumeric = @intBPFolderCount, 
	FolderProcessInfo.StampDate = getdate(), FolderProcessInfo.StampUser = @UserID
WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
AND FolderProcessInfo.InfoCode = 23003

UPDATE FolderProcessInfo
SET FolderProcessInfo.InfoValue = @intBPFolderReadyCount, 
	FolderProcessInfo.InfoValueNumeric = @intBPFolderReadyCount, 
	FolderProcessInfo.StampDate = getdate(), FolderProcessInfo.StampUser = @UserID
WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
AND FolderProcessInfo.InfoCode = 23004

SELECT @intUCOStatusCode = Folder.StatusCode, 
	   @dtUCOInDate = Folder.InDate, 
	   @varUCOFolderCondition = Folder.FolderCondition
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

IF @varUCOFolderCondition IS NULL
BEGIN
	UPDATE Folder
	SET Folder.FolderCondition = 'UCO Request Received (' + CONVERT(CHAR(11), @dtUCOInDate) + ')'
	WHERE Folder.FolderRSN = @FolderRSN
END

IF @intSubCode IN (23001, 23003) AND @intWorkCode <> 23002
BEGIN
	SELECT @varProcessNote = 'Project is UCO Ready'
	SELECT @varProcessAttemptNote = RTRIM(CAST(@intInfoFieldCount AS CHAR)) + ' permits processed. UCO Ready.'

	UPDATE Folder
	SET Folder.StatusCode = 23004,      /* UCO Pending */
		Folder.FolderCondition = 
			CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000),FolderCondition)) + 
			' -> ' + RTRIM(CAST(@intZPFolderCount AS CHAR)) + ' Zoning Permits and ' + 
					 RTRIM(CAST(@intBPFolderCount AS CHAR)) + 
				   ' Building Permits Ready for UCO Issuance (' + 
					 CONVERT(CHAR(11), getdate()) + ')' ))
	FROM Folder 
	WHERE Folder.FolderRSN = @FolderRSN
END
ELSE
BEGIN
	IF @intSubCode IN (23003, 23004) AND @intWorkCode <> 23002
	BEGIN
		SELECT @varProcessNote = 'Project is TCO Ready'
		SELECT @varProcessAttemptNote = RTRIM(CAST(@intInfoFieldCount AS CHAR)) + ' permits processed. TCO Ready.'

		UPDATE Folder
		SET Folder.StatusCode = 23009,      /* TCO Pending */
			Folder.FolderCondition = 
				CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000),FolderCondition)) + 
				' -> ' + RTRIM(CAST(@intZPFolderCount AS CHAR)) + ' Zoning Permits and ' + 
						 RTRIM(CAST(@intBPFolderCount AS CHAR)) + 
					   ' Building Permits Ready for TCO Issuance (' + 
						 CONVERT(CHAR(11), getdate()) + ')' ))
		FROM Folder 
		WHERE Folder.FolderRSN = @FolderRSN
	END
	ELSE
	BEGIN
		SELECT @varProcessNote = 'Project Not Ready'
		SELECT @varProcessAttemptNote = RTRIM(CAST(@intInfoFieldCount AS CHAR)) + ' permits processed. Not Ready.'

		IF @intUCOStatusCode = 23010		/* UCO Noncompliant */
		BEGIN
			UPDATE Folder
			SET Folder.IssueDate = NULL, Folder.ExpiryDate = NULL, Folder.FinalDate = NULL
			FROM Folder
			WHERE Folder.FolderRSN = @FolderRSN 
		END
		ELSE
		BEGIN
			UPDATE Folder
			SET Folder.StatusCode = 23002,      /* UCO In Process */
				Folder.IssueDate = NULL, Folder.ExpiryDate = NULL, Folder.FinalDate = NULL
			FROM Folder
			WHERE Folder.FolderRSN = @FolderRSN
		END
	END
END

UPDATE FolderProcess
SET FolderProcess.StatusCode = 1, 
	FolderProcess.ProcessComment = @varProcessNote, 
	FolderProcess.ScheduleDate = getdate(),
	FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
	FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL 
WHERE FolderProcess.ProcessRSN = @ProcessRSN
AND FolderProcess.FolderRSN = @FolderRSN

UPDATE FolderProcessAttempt
SET FolderProcessAttempt.AttemptComment = @varProcessAttemptNote, 
	FolderProcessAttempt.AttemptBy = @UserID
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
  ( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
	FROM FolderProcessAttempt
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

GO
