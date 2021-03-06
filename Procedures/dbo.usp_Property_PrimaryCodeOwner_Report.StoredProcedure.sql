USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Property_PrimaryCodeOwner_Report]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Property_PrimaryCodeOwner_Report]
AS
BEGIN
	DECLARE @FolderRSN INT
	DECLARE @FolderType VARCHAR(2)
	DECLARE @PropertyRSN INT
	DECLARE @LastPropertyRSN INT
	DECLARE @PeopleRSN INT
	DECLARE @LastPeopleRSN INT
	DECLARE @PropertyAddress VARCHAR(100)
	DECLARE @PeopleName VARCHAR(100)

	CREATE TABLE tblMismatches(
		FolderRSN INT,
		FolderType VARCHAR(2),
		PropertyRSN INT,
		PeopleRSN INT /*,
		PropertyAddress VARCHAR(100),
		PeopleName VARCHAR(100) */
	)

	DECLARE curFolders CURSOR FOR
	SELECT FolderRSN, FolderType, PropertyRSN, PeopleRSN --, 
	--SUBSTRING(dbo.udf_GetPropertyAddress(PropertyRSN), 1, 100) AS PropertyAddress,
	--SUBSTRING(dbo.f_GetPeopleName(PeopleRSN), 1, 100) AS PeopleName
	FROM uvw_Property_PrimaryCodeOwner 
	WHERE 
	( (FolderType = 'RB'  AND StatusCode = 1)
	   OR (FolderType = 'MH'  AND StatusCode <> 20022)
	)
	ORDER BY PropertyRSN

	OPEN curFolders

	FETCH NEXT FROM curFolders INTO @FolderRSN, @FolderType, @PropertyRSN, @PeopleRSN--, @PropertyAddress, @PeopleName

	SET @LastPropertyRSN = @PropertyRSN
	SET @LastPeopleRSN = @PeopleRSN

	WHILE @@FETCH_STATUS = 0 BEGIN

		IF @PropertyRSN = @LastPropertyRSN BEGIN
			IF @PeopleRSN <> @LastPeopleRSN BEGIN
				INSERT INTO tblMismatches 
				SELECT @FolderRSN, @FolderType, @PropertyRSN, @PeopleRSN--, @PropertyAddress, @PeopleName 
			END
		END

		SET @LastPropertyRSN = @PropertyRSN
		SET @LastPeopleRSN = @PeopleRSN

		FETCH NEXT FROM curFolders INTO @FolderRSN, @FolderType, @PropertyRSN, @PeopleRSN--, @PropertyAddress, @PeopleName
	END

	CLOSE curFolders
	DEALLOCATE curFolders

	SELECT * 
	FROM tblMismatches

	--DROP TABLE #Mismatches
END


GO
