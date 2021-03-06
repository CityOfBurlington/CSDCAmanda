USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Permit_Status_Rollback]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Permit_Status_Rollback] (@intFolderRSN int)
AS
BEGIN 
	/* Rolls back Zoning folder Status and Processes AFTER construction start and 
	permit expiration dates have been changed by a subsequent State or Federal permit 
	decision (FolderInfo.InfoCode = 10028). See InfoValidation (DefaultInfo_ZB). 
	Rollback occurs only when the folder is in a Permit Indeterminate status. */

	DECLARE @intStatusCode int 
	DECLARE @intNextStatusCode int
	DECLARE @varPermitPickedUp varchar(4)
	DECLARE @varPRCFlag varchar(2)
	DECLARE @varPhasingFlag varchar(2)
	DECLARE @dtPermitExpiryDate datetime
	DECLARE @dtConstructionStartDate datetime

	SELECT @intStatusCode = Folder.StatusCode, @intNextStatusCode = Folder.StatusCode
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN 

	IF @intStatusCode IN (10047, 10048) SELECT @varPhasingFlag = 'Y' 
	ELSE SELECT @varPhasingFlag = 'N' 

	IF @intStatusCode IN (10029, 10048, 10055)  /* Permit Indeterminate 1, 2, 3 */
	BEGIN
		SELECT @varPermitPickedUp = dbo.f_info_alpha (@intFolderRSN, 10023)
		SELECT @varPRCFlag = dbo.udf_ZoningPreReleaseConditionsFlag (@intFolderRSN) 
		SELECT @dtPermitExpiryDate = dbo.f_info_date (@intFolderRSN, 10024)
		SELECT @dtConstructionStartDate = dbo.f_info_date (@intFolderRSN, 10127) 

		IF @dtPermitExpiryDate > getdate()
		BEGIN
			IF @dtConstructionStartDate > getdate() 
			BEGIN
				IF @varPermitPickedUp IN ('Mailed', 'Yes') 
				BEGIN
					IF @varPhasingFlag = 'Y' SELECT @intNextStatusCode = 10047
					ELSE SELECT @intNextStatusCode = 10006
				END
				ELSE 
				BEGIN
					IF @varPRCFlag = 'Y' SELECT @intNextStatusCode = 10018 /* Pre-Release Conditions */
					ELSE SELECT @intNextStatusCode = 10005 
				END
			END
		END 
		ELSE SELECT @intNextStatusCode = 10055 /* Logic in InfoValidation won't let this happen */

		UPDATE Folder
		SET Folder.StatusCode = @intNextStatusCode 
		WHERE Folder.FolderRSN = @intFolderRSN 
	END

END


GO
