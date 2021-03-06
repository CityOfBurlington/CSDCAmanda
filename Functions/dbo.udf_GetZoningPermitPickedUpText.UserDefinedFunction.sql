USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningPermitPickedUpText]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningPermitPickedUpText](@intFolderRSN int, @intDecisionAttemptCode INT)
RETURNS VARCHAR(60)
AS
BEGIN 
	/* Returns text for recording to FolderConditions log */

	DECLARE @varFolderType varchar(4)
	DECLARE @varDecisionText varchar(60)
	
	SET @varDecisionText = ''
	
	SELECT @varFolderType = Folder.FolderType
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN 
	
	IF @varFolderType = 'ZP'		/* Master Plan Review */
	SELECT @varDecisionText = 
	CASE @intDecisionAttemptCode 
		WHEN 10002 THEN 'Denied Plan '
		WHEN 10003 THEN 'Approved Plan '
		WHEN 10011 THEN 'Approved Plan '
		WHEN 10020 THEN 'Denied Plan '
		ELSE ''
	END
	ELSE
	BEGIN 
		SELECT @varDecisionText = 
		CASE @intDecisionAttemptCode 
			WHEN 10002 THEN 'Reasons for Denial '
			WHEN 10003 THEN 'Approved Permit '
			WHEN 10006 THEN 'Upheld Decision Findings '
			WHEN 10007 THEN 'Overturned Decision Findings '
			WHEN 10011 THEN 'Approved Permit '
			WHEN 10017 THEN 'Approved NonApplicability '
			WHEN 10018 THEN 'Denied NonApplicability '
			WHEN 10020 THEN 'Reasons for Denial '
			WHEN 10046 THEN 'Affirmed Determination '
			WHEN 10047 THEN 'Adverse Determination '
			WHEN 10076 THEN 'Approved Permit ' 
			ELSE ''
		END
	END
	
	RETURN @varDecisionText
END
GO
