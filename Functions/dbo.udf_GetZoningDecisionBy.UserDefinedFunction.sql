USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningDecisionBy]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningDecisionBy](@intFolderRSN INT)
RETURNS VARCHAR(50)
AS
BEGIN
	/* Used by Infomaker zoning_all_permits form */
	DECLARE @varDecisionBy varchar(50)
	DECLARE @intSubCode int
	DECLARE @intAppealtoDRB int
	DECLARE @intAppealtoVSCED int
	DECLARE @intAppealtoVSC int

	SELECT @intSubCode = Folder.SubCode 
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

	SELECT @intAppealtoDRB = dbo.udf_GetProcessAttemptCode(@intFolderRSN, 10002)
	SELECT @intAppealtoVSCED = dbo.udf_GetProcessAttemptCode(@intFolderRSN, 10003)
	SELECT @intAppealtoVSC = dbo.udf_GetProcessAttemptCode(@intFolderRSN, 10029)

	SET @varDecisionBy = '?'

	SELECT @varDecisionBy = 
	CASE @intSubCode
		WHEN 10041 THEN 'Administrative'
		WHEN 10042 THEN 'Development Review Board'
		ELSE 'See Physical File'
	END

	/* DRB overturns an administrative decision */
	IF @intAppealtoDRB = 10007 SELECT @varDecisionBy = 'Development Review Board' 

	/* VSCED acts as DRB, so any approve/deny decision is theirs */
	IF @intAppealtoVSCED IN (10008, 10009, 10010, 10030, 10055) 
		SELECT @varDecisionBy = 'VT Superior Court Environmental Div' 

	/* VSC overturns a VSCED decision */
	IF @intAppealtoVSC = 10063 SELECT @varDecisionBy = 'Vermont Supreme Court' 

	RETURN @varDecisionBy
END
GO
