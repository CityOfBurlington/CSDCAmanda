USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetUCOPermitDescription]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetUCOPermitDescription](@intPermitFolderRSN INT, @UCOFolderRSN INT) 
RETURNS varchar(1000)
AS
BEGIN
	/* Returns individual permit descriptions for the UCO Infomaker form. 
	   There is a 255 character limit to the length of text fields, set by Infomaker's DB connection. 
	   So long Folder.FolderDescriptions may be truncated. */

	/* 0 = Not a Building Permit
	   1 = BP Not Required
	   2 = CO Required for BP
	   3 = CO Not Required for BP */

	DECLARE @varFolderType varchar(4)
	DECLARE @intWorkCode int 
	DECLARE @varPermitDescription varchar(800)
	DECLARE @intBPCORequiredInfoCount int 
	DECLARE @varBPCORequiredInfoValue varchar(3) 
	DECLARE @intBPTypeCode int 
	DECLARE @varClauseText varchar(200)
	DECLARE @intUCOPhaseNumberInfoCount int
	DECLARE @intUCOPhaseNumberInfoValue int
	DECLARE @varUCOPermitDescription varchar(1000)
	DECLARE @intPCOProcessRSN int

	SELECT @varFolderType = Folder.FolderType, @intWorkCode = Folder.WorkCode, 
		   @varPermitDescription = Folder.FolderDescription 
	FROM Folder 
	WHERE Folder.FolderRSN = @intPermitFolderRSN 
	
	SELECT @intUCOPhaseNumberInfoCount = COUNT(*)
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @UCOFolderRSN
	AND FolderInfo.InfoCode = 23035

	IF @intUCOPhaseNumberInfoCount > 0
	BEGIN
		SELECT @intUCOPhaseNumberInfoValue = ISNULL(FolderInfo.InfoValueNumeric, 0)
		FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @UCOFolderRSN
		AND FolderInfo.InfoCode = 23035
	END
	ELSE SELECT @intUCOPhaseNumberInfoValue = 0

	IF @varFolderType LIKE 'Z%' 
	BEGIN
		SELECT @intPCOProcessRSN = dbo.udf_GetUCOPhasePermitProcessRSN(@intPermitFolderRSN, @intUCOPhaseNumberInfoValue) 
		
		IF @intPCOProcessRSN > 0	/* Project Phasing */
		BEGIN
			SELECT @varUCOPermitDescription = FolderProcess.ProcessComment	/* Phase description text set up by Project Manager */ 
			FROM FolderProcess
			WHERE FolderProcess.ProcessRSN = @intPCOProcessRSN 
		END
		ELSE SELECT @varUCOPermitDescription = @varPermitDescription
	END

	IF @varFolderType IN ('BP','EP','MP')
	BEGIN
		SELECT @intBPCORequiredInfoCount = COUNT(*)
		FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @intPermitFolderRSN
		AND FolderInfo.InfoCode = 30059

		IF @intBPCORequiredInfoCount > 0
		BEGIN
			SELECT @varBPCORequiredInfoValue = FolderInfo.InfoValueUpper
			FROM FolderInfo
			WHERE FolderInfo.FolderRSN = @intPermitFolderRSN
			AND FolderInfo.InfoCode = 30059
		END
		ELSE SELECT @varBPCORequiredInfoValue = 'NO'

		IF @intWorkCode = 30110  /* BP Not Required */
			SELECT @intBPTypeCode = 1
		ELSE 
		BEGIN
			IF  @varBPCORequiredInfoValue = 'YES' SELECT @intBPTypeCode = 2  
			ELSE SELECT @intBPTypeCode = 3 
		END

		IF @intBPTypeCode = 1    /* BP Not Required */
		BEGIN
			SELECT @varUCOPermitDescription = ValidClause.ClauseText 
			FROM ValidClause
			WHERE ValidClause.ClauseRSN = 438 
		END

		IF @intBPTypeCode = 2    /* CO Required for BP */
		BEGIN
			SELECT @varUCOPermitDescription = @varPermitDescription 
		END

		IF @intBPTypeCode = 3    /* CO Not Required for BP */
		BEGIN
			SELECT @varUCOPermitDescription = ValidClause.ClauseText 
			FROM ValidClause
			WHERE ValidClause.ClauseRSN = 437 
		END
	END

	RETURN ISNULL(@varUCOPermitDescription, ' ')
END

GO
