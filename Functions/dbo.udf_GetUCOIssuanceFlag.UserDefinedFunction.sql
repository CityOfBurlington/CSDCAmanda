USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetUCOIssuanceFlag]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetUCOIssuanceFlag](@intPermitFolderRSN INT) 
RETURNS VARCHAR(2)
AS
BEGIN
	/* For individual permits in a UCO folder, return 'Y' if the individual permit is ready 
	   for UCO issuance, and 'N' if not ready. Used by the UCO InfoMaker form.  Uses folder 
	   status only. Accounts for project phasing. The form will not to display a permits 
	   if all the permits are not UCO ready. */

	DECLARE @intPermitFolderStatus int
	DECLARE @intZPPhaseNumberInfoCount int
	DECLARE @intZPPhaseNumberInfoValue int
	DECLARE @varCOReadyFlag varchar(2)
	
	SET @varCOReadyFlag= 'N'

	SELECT @intPermitFolderStatus = Folder.StatusCode
	FROM Folder 
	WHERE Folder.FolderRSN = @intPermitFolderRSN 
	
	SELECT @intZPPhaseNumberInfoCount = COUNT(*)
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @intPermitFolderRSN
	AND FolderInfo.InfoCode = 10081    /* Number of Phases */

	IF @intZPPhaseNumberInfoCount > 0
	BEGIN
		SELECT @intZPPhaseNumberInfoValue = ISNULL(FolderInfo.InfoValueNumeric, 0) 
		FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @intPermitFolderRSN
		AND FolderInfo.InfoCode = 10081 
	END
	ELSE SELECT @intZPPhaseNumberInfoValue = 0
	
	IF @intZPPhaseNumberInfoValue > 0 AND @intPermitFolderStatus IN (2, 10008, 10047, 10048, 10055) SELECT @varCOReadyFlag = 'Y' 
	ELSE
	BEGIN
		IF @intPermitFolderStatus IN (2, 10008) SELECT @varCOReadyFlag = 'Y'
	END

	RETURN @varCOReadyFlag 
END
GO
