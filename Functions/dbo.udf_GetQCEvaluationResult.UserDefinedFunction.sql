USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetQCEvaluationResult]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetQCEvaluationResult](@intFolderRSN INT) RETURNS VARCHAR(4000)
AS
BEGIN

	DECLARE @strEvalResult VARCHAR(30)
	DECLARE @intEvalResult INT
	DECLARE @intProcessRSN INT

	SET @strEvalResult = ' '

	/* Get ProcessRSN for Code Complaint Evaluation process (code = 20018) */
	SELECT @intProcessRSN = ProcessRSN 
	FROM FolderProcess 
	WHERE FolderRSN = @intFolderRSN AND ProcessCode = 20018

	/* Get Result Code from FolderProcessAttempt */
	SELECT @intEvalResult = ResultCode
	FROM FolderProcessAttempt
	WHERE FolderRSN = @intFolderRSN AND ProcessRSN = @intProcessRSN
	AND AttemptRSN = (SELECT MAX(AttemptRSN) 
		FROM FolderProcessAttempt 
		WHERE ProcessRSN = @intProcessRSN AND FolderRSN = @intFolderRSN)

	/* Lookup Result Description in ValidProcessAttemptResult */
	SELECT @strEvalResult = ResultDesc
	FROM ValidProcessAttemptResult
	WHERE ResultCode = @intEvalResult 

RETURN @strEvalResult
END
GO
