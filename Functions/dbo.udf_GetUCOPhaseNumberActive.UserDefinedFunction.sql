USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetUCOPhaseNumberActive]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetUCOPhaseNumberActive](@intFolderRSN INT) 
RETURNS INT
AS
BEGIN
	/* For UCO issuance: Each Phase receives its own UCO. 
	   Returns the highest active Phase Number from FolderProcessInfo Phase Number 
	   (10010) for Phased projects. The Active Phase is the last phase (Max ProcessRSN) 
	   that had CO Requested (10001) attempt result using a Phased CO process (10030). */

	DECLARE @intNumberPCOProcesses int
	DECLARE @intActivePhaseProcessRSN int
	DECLARE @intPhaseNumber int

	SET @intPhaseNumber = 0

	SELECT @intNumberPCOProcesses = dbo.udf_CountProcesses(@intFolderRSN, 10030)
	IF @intNumberPCOProcesses > 0
	BEGIN
		SELECT @intActivePhaseProcessRSN = ISNULL(MAX(FolderProcessAttempt.ProcessRSN), 0)
		FROM FolderProcess, FolderProcessAttempt
		WHERE FolderProcess.FolderRSN = @intFolderRSN 
		AND FolderProcess.ProcessCode = 10030
		AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
		AND FolderProcessAttempt.ResultCode = 10001	/* CO Requested */
				
		IF @intActivePhaseProcessRSN > 0
		BEGIN
			SELECT @intPhaseNumber = ISNULL(FolderProcessInfo.InfoValueNumeric, 0)
			FROM FolderProcessInfo
			WHERE FolderProcessInfo.ProcessRSN = @intActivePhaseProcessRSN
			AND FolderProcessInfo.InfoCode = 10010
		END
	END

	RETURN @intPhaseNumber
END

GO
