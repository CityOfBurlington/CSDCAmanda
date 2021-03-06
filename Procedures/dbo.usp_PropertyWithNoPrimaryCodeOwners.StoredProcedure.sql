USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_PropertyWithNoPrimaryCodeOwners]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_PropertyWithNoPrimaryCodeOwners] AS
BEGIN

DECLARE @FolderRSN VARCHAR(15)

/*
	CREATE TABLE tblMissingPCO(
		FolderRSN INT
	)
*/

TRUNCATE TABLE tblMissingPCO

DECLARE curProperties CURSOR FOR 
SELECT DISTINCT FolderRSN
FROM Folder
WHERE Folder.FolderType = 'RB'
AND Folder.FolderYear = '11'
--ISNULL(PropertyRoll, '') <> ''

OPEN curProperties

FETCH NEXT FROM curProperties INTO @FolderRSN

WHILE @@FETCH_STATUS = 0
BEGIN
	IF NOT EXISTS(SELECT PeopleRSN
			FROM FolderPeople
			WHERE FolderPeople.PeopleCode = 322
			AND FolderRSN = @FolderRSN)
		BEGIN
		INSERT INTO tblMissingPCO SELECT @FolderRSN
	END

	FETCH NEXT FROM curProperties INTO @FolderRSN
END

CLOSE curProperties
DEALLOCATE curProperties

END
GO
