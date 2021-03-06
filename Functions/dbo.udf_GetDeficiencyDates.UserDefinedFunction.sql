USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetDeficiencyDates]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetDeficiencyDates](@ProcessRSN INT) RETURNS VARCHAR(30)
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
		SELECT @strRetVal = dbo.udf_Trunc(MIN(AttemptDate))
		FROM FolderProcessAttempt 
		WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
		AND FolderProcessAttempt.ResultCode = 45

	END
ELSE
	BEGIN
		SELECT @strRetVal = dbo.udf_Trunc(MIN(AttemptDate)) + ' - ' + dbo.udf_Trunc(MAX(AttemptDate))
		FROM FolderProcessAttempt
		WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
		AND FolderProcessAttempt.ResultCode = 45
	END

RETURN @strRetVal

END




GO
