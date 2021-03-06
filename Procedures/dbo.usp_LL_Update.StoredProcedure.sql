USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_LL_Update]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_LL_Update](@Year CHAR(2)) 
AS
BEGIN
	DECLARE @FolderRSN		INT
	DECLARE @PeopleRSN		INT
	DECLARE @DBAName		VARCHAR(100)
	DECLARE @GrossReceiptID	VARCHAR(100)
	DECLARE @PersonalPropID	VARCHAR(100)
	DECLARE @CommonAreaID	VARCHAR(100)

	DECLARE curFolders CURSOR FOR
	SELECT Folder.FolderRSN,
	dbo.udf_GetFirstPeopleRSNByPeopleCode(700, Folder.FolderRSN) AS PeopleRSN,
	dbo.f_info_alpha(Folder.FolderRSN, 7004) AS DBAName,
	dbo.f_info_alpha(Folder.FolderRSN, 7001) AS GrossReceiptID,
	dbo.f_info_alpha(Folder.FolderRSN, 7002) AS PersonalPropID,
	dbo.f_info_alpha(Folder.FolderRSN, 7003) AS CommonAreaID
	FROM Folder
	WHERE FolderYear = @Year
	AND FolderType = 'LL'
	ORDER BY 2

	OPEN curFolders

	FETCH NEXT FROM curFolders INTO @FolderRSN, @PeopleRSN, @DBAName, 
		@GrossReceiptID, @PersonalPropID, @CommonAreaID

	WHILE @@FETCH_STATUS = 0
		BEGIN

		UPDATE Folder
		SET FolderName = @DBAName
		WHERE FolderRSN = @FolderRSN

		IF RTRIM(LTRIM(ISNULL(@GrossReceiptID, ''))) = ''
			BEGIN
			UPDATE FolderInfo
			SET InfoValue = dbo.f_info_alpha_people(@PeopleRSN, 7001),
			InfoValueUpper = UPPER(dbo.f_info_alpha_people(@PeopleRSN, 7001))
			WHERE FolderRSN = @FolderRSN
			AND InfoCode = 7001
		END

		IF RTRIM(LTRIM(ISNULL(@PersonalPropID, ''))) = ''
			BEGIN
			UPDATE FolderInfo
			SET InfoValue = dbo.f_info_alpha_people(@PeopleRSN, 7002),
			InfoValueUpper = UPPER(dbo.f_info_alpha_people(@PeopleRSN, 7002))
			WHERE FolderRSN = @FolderRSN
			AND InfoCode = 7002
		END

		IF RTRIM(LTRIM(ISNULL(@CommonAreaID, ''))) = ''
			BEGIN
			UPDATE FolderInfo
			SET InfoValue = dbo.f_info_alpha_people(@PeopleRSN, 7003),
			InfoValueUpper = UPPER(dbo.f_info_alpha_people(@PeopleRSN, 7003))
			WHERE FolderRSN = @FolderRSN
			AND InfoCode = 7003
		END


		FETCH NEXT FROM curFolders INTO @FolderRSN, @PeopleRSN, @DBAName, 
			@GrossReceiptID, @PersonalPropID, @CommonAreaID
	END

	CLOSE curFolders
	DEALLOCATE curFolders
END


GO
