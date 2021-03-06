USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningPreReleaseConditionsFlag]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZoningPreReleaseConditionsFlag](@intFolderRSN INT)
RETURNS varchar(2)
AS
BEGIN 
	/* Returns N if Prerelease Conditions are not applicable, or have been met. 
	   Returns Y if PreRelease Conditions are applicable, have not been met, and 
	   if the PRC process status is Open. */

	DECLARE @intPreReleaseConditionsApplicable int
	DECLARE @intPreReleaseConditionsMet int
	DECLARE @intPRCProcessStatus int
	DECLARE @varPRCFlag varchar(2)

	SET @varPRCFlag = 'N'   

	SELECT @intPreReleaseConditionsApplicable = dbo.udf_CountProcesses(@intFolderRSN, 10006)
	SELECT @intPreReleaseConditionsMet = dbo.udf_GetProcessAttemptCode(@intFolderRSN, 10006)

	IF @intPreReleaseConditionsApplicable > 0   /* PRCs are applicable */
	BEGIN
		SELECT @intPRCProcessStatus = FolderProcess.StatusCode
		FROM FolderProcess
		WHERE FolderProcess.FolderRSN = @intFolderRSN
		AND FolderProcess.ProcessCode = 10006

		IF @intPreReleaseConditionsMet = 10028 SELECT @varPRCFlag = 'N'
		ELSE 
		BEGIN
			IF @intPRCProcessStatus = 1 SELECT @varPRCFlag = 'Y'
			ELSE SELECT @varPRCFlag = 'N' 
		END
	END

	RETURN @varPRCFlag 
END

GO
