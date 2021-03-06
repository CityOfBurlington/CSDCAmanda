USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_SummarizeAttemptStatus]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_SummarizeAttemptStatus](@ProcessRSN INT) RETURNS VARCHAR(100)
AS
BEGIN
DECLARE @strRetVal VARCHAR (50)
DECLARE @intAttempts  INT

SELECT @intAttempts = SUM(1)
FROM FolderProcess
LEFT OUTER JOIN FolderProcessAttempt ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
WHERE FolderProcess.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.ResultCode = 45

IF @intAttempts = 1
	BEGIN
		SET @strRetVal = 'Deficiencies Found'
	END
ELSE
	BEGIN
		IF @intAttempts > 1
			BEGIN
				SELECT @strRetVal = 'Deficiencies Found on ' + CAST(@intAttempts AS VARCHAR(3)) + ' Inspections'
				FROM FolderProcessAttempt
				WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
				AND FolderProcessAttempt.ResultCode = 45
			END
		ELSE
			BEGIN
				SELECT @strRetVal = ValidProcessAttemptResult.ResultDesc
				FROM FolderProcessAttempt
				INNER JOIN ValidProcessAttemptResult ON FolderProcessAttempt.ResultCode = ValidProcessAttemptResult.ResultCode
				WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
				AND FolderProcessAttempt.ResultCode <> 45
			END
	END
RETURN @strRetVal

END



GO
