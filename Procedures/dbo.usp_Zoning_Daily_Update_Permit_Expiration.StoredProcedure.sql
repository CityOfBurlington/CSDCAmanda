USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Daily_Update_Permit_Expiration]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Daily_Update_Permit_Expiration]
AS 
BEGIN
/* Set approved permit status to Permit Indeterminant (10029 for single-phase projects, 
   or 10048 for multi-phase projects) for folders where the Construction Start Deadline date 
   has passed; are in Released, Ready to Release, Pre-Release Conditions,or Project Phasing 
   status; and Z3 Final and Combination Plats.  Z3 Preliminary Plat becomes Review Complete.  */

	/* Disable Folder Triggers so this doesn't lock up the database. */
	ALTER TABLE Folder DISABLE TRIGGER Folder_Upd
	ALTER TABLE Folder DISABLE TRIGGER Folder_Upd_Log
	ALTER TABLE Folder DISABLE TRIGGER Folder_Upd_Sec
	ALTER TABLE Folder DISABLE TRIGGER Folder_Upd_StampDate


	DECLARE @intFolderRSN int 
	DECLARE @varFolderType varchar(4)
	DECLARE @intWorkCode int
	DECLARE @intPhaseNumber int
	DECLARE @intNextStatusCode int
	
	DECLARE ExpiredFolders CURSOR FOR
	SELECT Folder.FolderRSN, Folder.FolderType, Folder.WorkCode
	FROM Folder, FolderInfo
	WHERE Folder.FolderType IN ('Z1', 'Z2', 'Z3', 'ZA', 'ZB', 'ZC', 'ZF', 'ZH', 'ZZ')
	AND Folder.StatusCode IN (10005, 10006, 10018, 10047)
	AND Folder.FolderRSN = FolderInfo.FolderRSN
	AND FolderInfo.InfoCode = 10127        /* Construction Start Deadline */
	AND FolderInfo.InfoValueDateTime < getdate()

	OPEN ExpiredFolders
	FETCH NEXT FROM ExpiredFolders INTO @intFolderRSN, @varFolderType, @intWorkCode
	WHILE @@Fetch_Status = 0 
	BEGIN
		SET @intPhaseNumber = 1
		SELECT @intPhaseNumber = ISNULL(FolderInfo.InfoValueNumeric, 1) 
		FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @intFolderRSN
		AND FolderInfo.InfoCode = 10081

		IF @intPhaseNumber > 1 SELECT @intNextStatusCode = 10048		/* Permit Indeterminant 2 (Phased Projects) */
		ELSE SELECT @intNextStatusCode = 10029									/* Permit Indeterminant 1 (Single Phase Projects) */

		IF @varFolderType = 'Z3' 
		BEGIN
			IF @intWorkCode IN (10010, 10011)			/* Final and Combo Plats*/
			BEGIN
				UPDATE Folder
				SET Folder.StatusCode = @intNextStatusCode 
				WHERE Folder.FolderRSN = @intFolderRSN
			END
			IF @intWorkCode = 10009							/* Preliminary Plat */
			BEGIN
				UPDATE Folder
				SET Folder.StatusCode = 10031				/* Review Complete */
				WHERE Folder.FolderRSN = @intFolderRSN
			END
		END
		ELSE 				/* @varFolderType IN ('Z1', 'Z2', 'ZA', 'ZB', 'ZC', 'ZF', 'ZH', 'ZZ')  */
		BEGIN
			UPDATE Folder
			SET Folder.StatusCode = @intNextStatusCode 
			WHERE Folder.FolderRSN = @intFolderRSN
		END
		
		FETCH NEXT FROM ExpiredFolders INTO @intFolderRSN, @varFolderType, @intWorkCode
	END    
	CLOSE ExpiredFolders
	DEALLOCATE ExpiredFolders

	/* Set Folder Status to Permit Indeterminate 3 for projects whose Permit Expiration Date 
	has passed. */
	
	UPDATE Folder
	SET Folder.StatusCode = 10055          /* Permit Indeterminant 3 */
	FROM Folder, FolderInfo
	WHERE Folder.FolderType IN ('Z1', 'Z2', 'Z3', 'ZA', 'ZB', 'ZC', 'ZF', 'ZH', 'ZZ')
	AND Folder.StatusCode IN (10029, 10048)
	AND Folder.FolderRSN = FolderInfo.FolderRSN
	AND FolderInfo.InfoCode = 10024    /* Permit Expiration Date  */
	AND FolderInfo.InfoValueDateTime < getdate() 

	/* Set folder status to Master Plan Expired for approved Parking Master Plans (ZP). */
	
	UPDATE Folder
	SET Folder.StatusCode = 10042   /* Master Plan Expired */
	FROM Folder, FolderInfo 
	WHERE Folder.FolderType = 'ZP'
	AND Folder.StatusCode = 10041
	AND Folder.WorkCode IN (10006, 10008)      /* Parking Plan, Tree Maintenance Plan */
	AND Folder.FolderRSN = FolderInfo.FolderRSN
	AND FolderInfo.InfoCode = 10024
	AND FolderInfo.InfoValueDateTime < getdate()


	/* Turn the Folder Triggers back on. */
	ALTER TABLE Folder ENABLE TRIGGER Folder_Upd
	ALTER TABLE Folder ENABLE TRIGGER Folder_Upd_Log
	ALTER TABLE Folder ENABLE TRIGGER Folder_Upd_Sec
	ALTER TABLE Folder ENABLE TRIGGER Folder_Upd_StampDate

END

GO
