USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningDecisionProcessCode]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningDecisionProcessCode](@intFolderRSN INT)
RETURNS INT
AS
BEGIN
	DECLARE @varFolderType varchar(4)
	DECLARE @intDecisionProcessCode int
	DECLARE @intAppealtoDRBCount int
	DECLARE @intAppealtoDRBAttemptCount int
	DECLARE @intAppealtoVSCEDCount int
	DECLARE @intAppealtoVSCEDAttemptCount int
	DECLARE @intAppealtoVSCCount int
	DECLARE @intAppealtoVSCAttemptCount int

	SET @intDecisionProcessCode = 0

	SELECT @varFolderType = Folder.FolderType
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

/*	IF @varFolderType = 'ZL'		/* Misc Zoning Appeal */
	BEGIN
		SELECT @intAppealtoDRBCount = dbo.udf_CountProcesses(@intFolderRSN, 10002)
		SELECT @intAppealtoDRBAttemptCount = dbo.udf_CountProcessAttemptResults(@intFolderRSN, 10002)
		
		SELECT @intAppealtoVSCEDCount = dbo.udf_CountProcesses(@intFolderRSN, 10003)
		SELECT @intAppealtoVSCEDAttemptCount = dbo.udf_CountProcessAttemptResults(@intFolderRSN, 10003)
		
		SELECT @intAppealtoVSCCount = dbo.udf_CountProcesses(@intFolderRSN, 10029)
		SELECT @intAppealtoVSCAttemptCount = dbo.udf_CountProcessAttemptResults(@intFolderRSN, 10029)
		
		IF @intAppealtoDRBCount > 0   AND @intAppealtoDRBAttemptCount > 0    SELECT @intDecisionProcessCode = 10002
		IF @intAppealtoVSCEDCount > 0 AND @intAppealtoVSCEDAttemptCount  > 0 SELECT @intDecisionProcessCode = 10003
		IF @intAppealtoVSCCount > 0   AND @intAppealtoVSCAttemptCount > 0    SELECT @intDecisionProcessCode = 10029
	END
	ELSE
	BEGIN */
		SELECT @intDecisionProcessCode = 
		CASE @varFolderType
			WHEN 'ZD' THEN 10016
			WHEN 'ZL' THEN 10002
			WHEN 'ZN' THEN 10010
			WHEN 'ZS' THEN 0
			WHEN 'ZZ' THEN 10014
			ELSE 10005
		END
	/* END */

	RETURN @intDecisionProcessCode
END

GO
