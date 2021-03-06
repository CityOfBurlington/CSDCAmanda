USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetUCOIssuanceStatus]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetUCOIssuanceStatus](@intPermitFolderRSN INT, @intUCOFolderRSN int) 
RETURNS VARCHAR(20)
AS
BEGIN
	/* For individual permits in a UCO folder, returns 'UCO Ready' if the individual permit is ready 
	   for UCO issuance, 'TCO Ready' if the individual permit is ready for TCO issuance, 'TCO Expired' 
	   if the individual permit is ready for TCO issuance, and 'Not Ready' if not ready for anything. 
	   Used by the UCO InfoMaker form, uco_permit_report.  Accounts for project phasing. */

	DECLARE @intPermitFolderStatus int
	DECLARE @intPCOProcessRSN int
	DECLARE @intUCOPhaseNumberCount int
	DECLARE @intUCOPhaseNumberValue int
	DECLARE @varPCOProcessStatusCode int
	DECLARE @intPCOProcessAttemptResultCount int
	DECLARE @intPCOProcessLastAttemptResult int
	DECLARE @varReadyStatus varchar(20)
	
	SET @varReadyStatus = 'Not Ready'

	SELECT @intPermitFolderStatus = Folder.StatusCode
	FROM Folder 
	WHERE Folder.FolderRSN = @intPermitFolderRSN 
	
	SELECT @intUCOPhaseNumberCount = COUNT(*)
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @intUCOFolderRSN
	AND FolderInfo.InfoCode = 23035

	IF @intUCOPhaseNumberCount > 0
	BEGIN
		SELECT @intUCOPhaseNumberValue = ISNULL(FolderInfo.InfoValueNumeric, 0)
		FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @intUCOFolderRSN
		AND FolderInfo.InfoCode = 23035
	END
	ELSE SELECT @intUCOPhaseNumberValue = 0 
	
	SELECT @intPCOProcessRSN = dbo.udf_GetUCOPhasePermitProcessRSN(@intPermitFolderRSN, @intUCOPhaseNumberValue) 

	IF @intPCOProcessRSN > 0       /* Project Phasing */
	BEGIN
		SELECT @varPCOProcessStatusCode = FolderProcess.StatusCode
		FROM FolderProcess
		WHERE FolderProcess.ProcessRSN = @intPCOProcessRSN 
		
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

		IF @varPCOProcessStatusCode = 2		/* Closed by either Approved for Phase CO (10066) or Abandon Phase (10067) */
		BEGIN
			IF @intPCOProcessLastAttemptResult = 10066 SELECT @varReadyStatus = 'UCO Ready'
			ELSE SELECT @varReadyStatus = 'Not Ready'
		END
		ELSE
		BEGIN
			SELECT @varReadyStatus = 
			CASE @varPCOProcessStatusCode
				WHEN 10004 THEN 'TCO Ready'
				WHEN 10005 THEN 'TCO Expired'
				ELSE 'Not Ready'
			END
		END
	END
	ELSE		/* Single Phase Projects */
	BEGIN	
		SELECT @varReadyStatus = 
		CASE @intPermitFolderStatus
			WHEN 2 THEN 'UCO Ready'
			WHEN 10007 THEN 'TCO Ready'
			WHEN 10008 THEN 'UCO Ready'
			WHEN 10013 THEN 'TCO Expired'
			ELSE 'Not Ready'
		END
	END
	
	RETURN @varReadyStatus 
END

GO
