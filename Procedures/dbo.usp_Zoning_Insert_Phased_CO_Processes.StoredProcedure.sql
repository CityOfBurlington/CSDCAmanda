USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Insert_Phased_CO_Processes]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[usp_Zoning_Insert_Phased_CO_Processes] (@intFolderRSN int, @varUserID varchar(20))
AS
BEGIN 
	/* Called by InfoValidation for FolderInfo.InfoCodes 10023 (Permit Picked Up) and 10081 (Number of Phases). */

	DECLARE @intPCOProcessCode int
	DECLARE @intNumberofPhasesInfoCount int 
	DECLARE @intNumberofPhases int 
	DECLARE @intFolderStatus int
	DECLARE @intNumberofProcesses10001 int
	DECLARE @intNumberofProcesses10030 int
	DECLARE @intDisplayOrder int 
	DECLARE @intCounter int
	DECLARE @intCOProcessRSN int
	DECLARE @intPCOProcessRSN int
	DECLARE @intNextProcessRSN int
	DECLARE @varPhaseText varchar(20)
	DECLARE @varPreReleaseConditionsFlag varchar(2)
	DECLARE @intWaiveAppealAttempt int
	DECLARE @varLogText varchar(400)

	SET @intPCOProcessCode = 10030 

	SELECT @intNumberofPhasesInfoCount = COUNT (*)
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @intFolderRSN 
	AND FolderInfo.InfoCode = 10081

	IF @intNumberofPhasesInfoCount > 0
	BEGIN
		SELECT @intNumberofPhases = CAST(ROUND(ISNULL(FolderInfo.InfoValueNumeric, 0), 0) AS INT)
		FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @intFolderRSN 
		AND FolderInfo.InfoCode = 10081
	END
	ELSE SELECT @intNumberofPhases = 0

	SELECT @intFolderStatus = Folder.StatusCode 
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

	/* Procedure runs only when the Folder.StatusCode is Released (10006) or Project Phasing (10047). */

	IF @intFolderStatus IN (10006, 10047)
	BEGIN 
		SELECT @intNumberofProcesses10001 = dbo.udf_CountProcesses(@intFolderRSN, 10001)
		SELECT @intNumberofProcesses10030 = dbo.udf_CountProcesses(@intFolderRSN, @intPCOProcessCode)

		SELECT @intDisplayOrder = DefaultProcess.DisplayOrder + 10 + @intNumberofProcesses10030
		FROM DefaultProcess 
		WHERE DefaultProcess.ProcessCode = 10019  /* Abandon Permit */ 
		
		/* Delete Certificate of Occupancy process (single phase) */
		
		IF ( @intNumberofPhases > 1 AND @intNumberofProcesses10001 > 0 )
		BEGIN
			SELECT @intCOProcessRSN = ISNULL(FolderProcess.ProcessRSN, 0)
			FROM FolderProcess
			WHERE FolderProcess.FolderRSN = @intFolderRSN 
			AND FolderProcess.ProcessCode = 10001

			DELETE FROM FolderProcess
			WHERE FolderProcess.ProcessRSN = @intCOProcessRSN 
			AND FolderProcess.FolderRSN = @intFolderRSN
			AND FolderProcess.ProcessCode = 10001 
		END

		/* Add Phased Certificate of Occupancy process(es) */

		IF ( @intNumberofPhases > 1 ) AND ( @intNumberofPhases > @intNumberofProcesses10030 ) 
		BEGIN
			SELECT @intCounter = @intNumberofProcesses10030 + 1 

			WHILE @intCounter <= @intNumberofPhases
			BEGIN
				SELECT @intNextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
				FROM FolderProcess

				INSERT INTO FolderProcess 
					( ProcessRSN, FolderRSN, ProcessCode, StartDate, StatusCode, DisciplineCode, 
					  PrintFlag, StampDate, StampUser, DisplayOrder )
				VALUES 
					( @intNextProcessRSN, @intFolderRSN, @intPCOProcessCode, getdate(), 1, 45, 
					  'Y', getdate(), @varUserID, @intDisplayOrder ) 

				UPDATE FolderProcessInfo
				SET FolderProcessInfo.InfoValue = @intCounter, 
					FolderProcessInfo.InfoValueNumeric = @intCounter
				WHERE FolderProcessInfo.ProcessRSN = @intNextProcessRSN 
				AND FolderProcessInfo.FolderRSN = @intFolderRSN
				AND FolderProcessInfo.InfoCode = 10010

				SELECT @intDisplayOrder = @intDisplayOrder + 1
				SELECT @intCounter = @intCounter + 1
			END
		END   /* End of add processes */

		/* Delete Phased Certificate of Occupancy process(es) */

		IF @intNumberofPhases < @intNumberofProcesses10030 
		BEGIN
			SELECT @intCounter = @intNumberofPhases + 1

			WHILE @intCounter < @intNumberofProcesses10030 + 1
			BEGIN
				SELECT @intPCOProcessRSN = ISNULL(FolderProcessInfo.ProcessRSN, 0)
				FROM FolderProcessInfo
				WHERE FolderProcessInfo.InfoValueNumeric = @intCounter
				AND FolderProcessInfo.FolderRSN = @intFolderRSN
				AND FolderProcessInfo.InfoCode = 10010 

				IF @intPCOProcessRSN > 0 
				BEGIN
					DELETE FROM FolderProcess
					WHERE FolderProcess.ProcessRSN = @intPCOProcessRSN 
					AND FolderProcess.FolderRSN = @intFolderRSN
					AND FolderProcess.ProcessCode = @intPCOProcessCode
				END

				SELECT @intCounter = @intCounter + 1
			END
		END   /* End of delete processes */

		/* Enter phase numbers into FolderProcess.ProcessComment */

		SELECT @intNumberofProcesses10030 = dbo.udf_CountProcesses(@intFolderRSN, @intPCOProcessCode)
		IF @intNumberofProcesses10030 > 0 
		BEGIN 
			SELECT @intCounter = 1
			SELECT @varPhaseText = 'Phase ' + RTRIM(CAST(@intCounter AS CHAR(2))) + ' of ' + RTRIM(CAST(@intNumberofPhases AS CHAR(2)))

			WHILE @intCounter < @intNumberofProcesses10030 + 1
			BEGIN
				SELECT @intPCOProcessRSN = ISNULL(FolderProcessInfo.ProcessRSN, 0)
				FROM FolderProcessInfo
				WHERE FolderProcessInfo.InfoValueNumeric = @intCounter
				AND FolderProcessInfo.FolderRSN = @intFolderRSN
				AND FolderProcessInfo.InfoCode = 10010 

				IF @intPCOProcessRSN > 0 
				BEGIN
					UPDATE FolderProcess 
					SET FolderProcess.ProcessComment = @varPhaseText 
					WHERE FolderProcess.ProcessRSN = @intPCOProcessRSN
					AND FolderProcess.FolderRSN = @intFolderRSN
					AND FolderProcess.ProcessCode = @intPCOProcessCode
				END

				SELECT @intCounter = @intCounter + 1
				SELECT @varPhaseText = 'Phase ' + RTRIM(CAST(@intCounter AS CHAR(2))) + ' of ' + RTRIM(CAST(@intNumberofPhases AS CHAR(2)))
			END
		END   /* End of phase text coding */

		/* If there is no phasing, delete all or any remaining Phased CO processes. */

		IF @intNumberofPhases < 2
		BEGIN
			DELETE FROM FolderProcess
			WHERE FolderProcess.FolderRSN = @intFolderRSN
			AND FolderProcess.ProcessCode = @intPCOProcessCode
		END

		/* Set Folder.StatusCode, and write log text to Folder.FolderCondition. 
		   For no phasing, setting StatusCode to Released triggers the insertion of the 
		   Certificate of Occupancy process (10001). */

		IF @intNumberofPhases < 2		/* No Phasing - folder status becomes Released */
		BEGIN 
			UPDATE Folder
			SET Folder.StatusCode = 10006 
			WHERE Folder.FolderRSN = @intFolderRSN
			
			SELECT @varLogText = '' 
		END
		ELSE							/* Phasing - folder status becomes Project Phasing */
		BEGIN 
			UPDATE Folder
			SET Folder.StatusCode = 10047
			WHERE Folder.FolderRSN = @intFolderRSN
			
			SELECT @varLogText = ' -> Project Construction in ' + CAST(@intNumberofPhases AS CHAR(2)) + ' Phases'
		END
		
		EXECUTE dbo.usp_Zoning_Update_FolderCondition_Log @intFolderRSN, @varLogText
		
	END			/* End of @intFolderStatus IN (10006, 10047) */
END




GO
