USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningPreReleaseConditionsFolderStatus]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZoningPreReleaseConditionsFolderStatus](@intFolderRSN INT, @dtCurrentDate datetime)
RETURNS INT
AS
BEGIN 
	/* Called by dbo.DefaultProcess_ZB_00010006 (Pre-Release Conditions). 
	Passes a new Folder.StatusCode value when Pre-Release Conditions are met. 
	Pre-Release conditions are not applied with ZD, ZS, and ZZ folders. 
	Use of getdate() is not allowed in functions - workaround is to pass the 
	current date value. 
	Check for Waive Right to Appeal (ProcessCode 10028) added 8/30/10. */

	DECLARE @varFolderType varchar(3)
	DECLARE @intFolderStatus int
	DECLARE @dtExpiryDate datetime
	DECLARE @intWorkCode int
	DECLARE @intNextStatusCode int
	DECLARE @intWaiveAppealAttempt int

	SET @intNextStatusCode = 10099       /* dummy status */

	SELECT @varFolderType = Folder.FolderType, 
		@intFolderStatus = Folder.StatusCode, 
		@dtExpiryDate = Folder.ExpiryDate, 
		@intWorkcode = Folder.WorkCode
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

	SELECT @intWaiveAppealAttempt = dbo.udf_GetProcessAttemptCode(@intFolderRSN, 10028)

	IF ( @dtExpiryDate > @dtCurrentDate AND @intWaiveAppealAttempt <> 10058 ) 
		SELECT @intNextStatusCode = 10002
	ELSE
	BEGIN
		IF @intFolderStatus IN (10009, 10017, 10036, 10046)	/* Under Appeal */
			SELECT @intNextStatusCode = @intFolderStatus
		ELSE
		BEGIN
			SELECT @intNextStatusCode = 
			CASE @varFolderType
				WHEN 'ZN' THEN 10031   /* Review Complete */
				WHEN 'ZP' THEN 10041   /* Master Plan Approved */
				ELSE 10005             /* Ready to Release */
			END
		END
	END

	RETURN @intNextStatusCode
END

GO
