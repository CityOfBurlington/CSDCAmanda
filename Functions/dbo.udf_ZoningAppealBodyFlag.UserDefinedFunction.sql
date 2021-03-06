USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningAppealBodyFlag]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZoningAppealBodyFlag](@intFolderRSN INT)
RETURNS VARCHAR(10)
AS
BEGIN 
	/* Returns the body that would hear an appeal: DRB, VSCED, VSC, or USSC. */
	/* If the VSCED Remands, the DRB and VSCED can each hear an appeal again. */
	/* When the DRB or VSC overturns previous decision, the converse attempt 
	   result is inserted into the application decision process. Therefore 
	   SELECT the attempt code and date for the previous attempt result. */

	DECLARE @intLastApplicationDecisionAttemptCode int
	DECLARE @dtLastApplicationDecisionAttemptDate datetime
	DECLARE @intApplicationDecisionAttemptCount int 
	DECLARE @intLastAppealDecisionAttemptCode int
	DECLARE @dtLastAppealDecisionAttemptDate datetime
	DECLARE @intSubCode int
	DECLARE @varAppealBody varchar(10)

	SET @intLastApplicationDecisionAttemptCode = 0
	SET @intLastAppealDecisionAttemptCode = 0
	SET @varAppealBody = 'ERROR' 

	SELECT @intSubCode = Folder.SubCode 
	FROM Folder 
	WHERE Folder.FolderRSN = @intFolderRSN 

	SELECT @intLastApplicationDecisionAttemptCode = FolderProcessAttempt.ResultCode, 
		@dtLastApplicationDecisionAttemptDate = FolderProcessAttempt.AttemptDate
	FROM FolderProcessAttempt, FolderProcess
	WHERE FolderProcessAttempt.FolderRSN = @intFolderRSN
	AND FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN 
	AND FolderProcess.ProcessCode IN (10005, 10010, 10016)
	AND FolderProcessAttempt.AttemptDate = ( 
		SELECT MAX(FolderProcessAttempt.AttemptDate)
		FROM FolderProcessAttempt, FolderProcess 
		WHERE FolderProcessAttempt.FolderRSN = @intFolderRSN
		AND FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN 
		AND FolderProcess.ProcessCode IN (10005, 10010, 10016) ) 

	SELECT @intLastAppealDecisionAttemptCode = FolderProcessAttempt.ResultCode, 
		@dtLastAppealDecisionAttemptDate = FolderProcessAttempt.AttemptDate
	FROM FolderProcessAttempt, FolderProcess
	WHERE FolderProcessAttempt.FolderRSN = @intFolderRSN
	AND FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN 
	AND FolderProcess.ProcessCode IN (10002, 10003, 10029)
	AND FolderProcessAttempt.AttemptDate = ( 
		SELECT MAX(FolderProcessAttempt.AttemptDate)
		FROM FolderProcessAttempt, FolderProcess 
		WHERE FolderProcessAttempt.FolderRSN = @intFolderRSN
		AND FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN 
		AND FolderProcess.ProcessCode IN (10002, 10003, 10029) ) 

	IF @intLastAppealDecisionAttemptCode IN (10007, 10063)    /* Overturn previous decision */
	BEGIN
		SELECT @intApplicationDecisionAttemptCount = COUNT(*)
		FROM FolderProcessAttempt, FolderProcess
		WHERE FolderProcessAttempt.FolderRSN = @intFolderRSN
		AND FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN 
		AND FolderProcess.ProcessCode IN (10005, 10010, 10016)

		SELECT @intLastApplicationDecisionAttemptCode = FolderProcessAttempt.ResultCode, 
			@dtLastApplicationDecisionAttemptDate = FolderProcessAttempt.AttemptDate
		FROM FolderProcessAttempt, FolderProcess
		WHERE FolderProcessAttempt.FolderRSN = @intFolderRSN
		AND FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN 
		AND FolderProcess.ProcessCode IN (10005, 10010, 10016)
		AND FolderProcessAttempt.AttemptRSN = @intApplicationDecisionAttemptCount - 1
	END

	IF @intLastAppealDecisionAttemptCode = 0   /* No Appeals have occurred */
	BEGIN 
		SELECT @varAppealBody = 
		CASE @intSubCode 
			WHEN 10041 THEN 'DRB'
			WHEN 10042 THEN 'VSCED'
			ELSE 'ERROR'
		END
	END
	ELSE      /* Appeals have occurred */
	BEGIN
		IF @dtLastApplicationDecisionAttemptDate > @dtLastAppealDecisionAttemptDate 
		BEGIN
			SELECT @varAppealBody = 
			CASE @intSubCode 
				WHEN 10041 THEN 'DRB'
				WHEN 10042 THEN 'VSCED'
				ELSE 'ERROR'		/* 10041 and 10042 are the only valid values */
			END 
		END
		ELSE
		BEGIN
			SELECT @varAppealBody = 
			CASE @intLastAppealDecisionAttemptCode 
				WHEN 10006 THEN 'VSCED'
				WHEN 10007 THEN 'VSCED'
				WHEN 10008 THEN 'VSC' 
				WHEN 10009 THEN 'VSC' 
				WHEN 10010 THEN 'VSC' 
				WHEN 10030 THEN 'VSC' 
				WHEN 10053 THEN 'VSC' 
				WHEN 10054 THEN 'VSC' 
				WHEN 10055 THEN 'VSC' 
				WHEN 10056 THEN 'VSC' 
				WHEN 10075 THEN 'VSC' 
				WHEN 10062 THEN 'USSC' 
				WHEN 10063 THEN 'USSC'
				ELSE 'ERROR'			/* AttemptCode IN (10004, 10048, 10052) */
			END 
		END
	END

	RETURN @varAppealBody
END

GO
