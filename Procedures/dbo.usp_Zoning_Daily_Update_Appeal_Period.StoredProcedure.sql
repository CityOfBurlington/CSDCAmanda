USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Daily_Update_Appeal_Period]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Daily_Update_Appeal_Period]
AS 
BEGIN
	/* Update Folder Status for the end of decision appeal periods. */
	/* Close open processes for permits out of appeal periods, except Pre-Release Conditions and CO-related processes. */

	DECLARE @intFolderRSN int
	DECLARE @varFolderType varchar(4)
	DECLARE @intStatusCode int
	DECLARE @intNextStatusCode int
	DECLARE @dtTimeExtensionAppealEndDate datetime

	DECLARE AppealOverFolders CURSOR FOR
	SELECT Folder.FolderRSN, Folder.FolderType, Folder.StatusCode 
	FROM Folder
	WHERE Folder.ExpiryDate < GETDATE()
	AND Folder.StatusCode IN (10001, 10002, 10003, 10004, 10016, 10022, 10027)
	AND Folder.FolderType IN ('Z1', 'Z2', 'Z3', 'ZA', 'ZB', 'ZC', 'ZD', 'ZF', 'ZH', 'ZL', 'ZN', 'ZP', 'ZS')
	
	OPEN AppealOverFolders
	FETCH NEXT FROM AppealOverFolders INTO @intFolderRSN, @varFolderType, @intStatusCode
	WHILE @@Fetch_Status = 0
	BEGIN
		SELECT @intNextStatusCode = dbo.udf_ZoningAppealPeriodEndFolderStatus (@intFolderRSN) 
		
		IF @varFolderType = 'ZS' AND @intStatusCode = 10001 
		BEGIN
			UPDATE Folder
			SET Folder.StatusCode = @intNextStatusCode, Folder.FinalDate = GETDATE()
			WHERE Folder.FolderRSN = @intFolderRSN
			
			UPDATE FolderProcess
			SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = GETDATE()
			FROM FolderProcess 
			WHERE FolderProcess.FolderRSN = @intFolderRSN 
			AND FolderProcess.StatusCode = 1 
			AND FolderProcess.ProcessCode IN (10000, 10007, 10012 ) 
		END
		ELSE
		BEGIN
			UPDATE Folder
			SET Folder.StatusCode = @intNextStatusCode
			WHERE Folder.FolderRSN = @intFolderRSN

			UPDATE FolderProcess
			SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = GETDATE()
			WHERE FolderProcess.FolderRSN = @intFolderRSN
			AND FolderProcess.StatusCode = 1 
			AND FolderProcess.ProcessCode IN (10000, 10002, 10003, 10004, 10005, 10007, 10008, 10010, 10012, 10014, 10016, 10018, 10020, 10028, 10029) 
		END 
		
		/* Send notification email(s) for approved permits - status Ready to Release (10005) and Pre-Release Conditions (10018). */
		
		IF @intNextStatusCode IN (10005, 10018)
			EXECUTE dbo.usp_Zoning_Notification_Permit_Ready_to_Release @intFolderRSN 

		FETCH NEXT FROM AppealOverFolders INTO @intFolderRSN, @varFolderType, @intStatusCode
	END
	CLOSE AppealOverFolders
	DEALLOCATE AppealOverFolders

	/* Update Folder Status for end of permit expiration time extension appeal periods. */
	
	DECLARE TXFolders CURSOR FOR
	SELECT Folder.FolderRSN
	FROM Folder
	WHERE Folder.StatusCode IN (10044, 10045) /* Time Extension appeal period */

	OPEN TXFolders
	FETCH NEXT FROM TXFolders INTO @intFolderRSN
	WHILE @@Fetch_Status = 0
	BEGIN
		SELECT @dtTimeExtensionAppealEndDate = FolderProcessInfo.InfoValueDateTime 
		FROM FolderProcessInfo
		WHERE FolderProcessInfo.InfoCode = 10009    /* Appeal Period Expiration Date */
		AND FolderProcessInfo.ProcessRSN = ( 
		SELECT MAX(FolderProcess.ProcessRSN) 
		FROM FolderProcess 
		WHERE FolderProcess.FolderRSN = @intFolderRSN 
		AND FolderProcess.ProcessCode = 10020 )     /* Extend Permit Expiration */

		UPDATE Folder 
		SET Folder.StatusCode = dbo.udf_ZoningAppealPeriodEndFolderStatus (@intFolderRSN) 
		WHERE Folder.FolderRSN = @intFolderRSN 
		AND @dtTimeExtensionAppealEndDate < getdate() 

		FETCH NEXT FROM TXFolders INTO @intFolderRSN
	END
	CLOSE TXFolders
	DEALLOCATE TXFolders
END
GO
