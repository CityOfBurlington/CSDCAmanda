USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Construction_Permit_Parents]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Construction_Permit_Parents]
AS
BEGIN

DECLARE @PropertyLocation	NVARCHAR(100)
DECLARE @FolderRSN			INT
DECLARE @FolderType			CHAR(2)
DECLARE @PropertyRSN		INT
DECLARE @FolderDate			DATETIME

TRUNCATE TABLE tempOrphans

DECLARE curOrphanFolders CURSOR FOR
SELECT Folder.FolderRSN, Folder.FolderType, Folder.PropertyRSN, Folder.FolderName, Folder.InDate
FROM Folder
INNER JOIN ValidFolder ON Folder.FolderType = ValidFolder.FolderType
WHERE ValidFolder.FolderGroupCode = 1 /*Construction Permits*/
AND Folder.InDate > DATEADD(D, -90, GetDate())
AND Folder.FolderType <> 'BP' /*BP is only parent, never orphan*/
AND Folder.ParentRSN IS NULL

OPEN curOrphanFolders

FETCH NEXT FROM curOrphanFolders INTO @FolderRSN, @FolderType, @PropertyRSN, @PropertyLocation, @FolderDate

WHILE @@FETCH_STATUS = 0
	BEGIN

	IF EXISTS(SELECT * FROM Folder 
			INNER JOIN ValidFolder ON Folder.FolderType = ValidFolder.FolderType
			WHERE PropertyRSN = @PropertyRSN 
			AND FolderRSN <> @FolderRSN
			AND ValidFolder.FolderGroupCode = 1 /*Construction Permits*/
			AND Folder.InDate > DATEADD(D, -90, GetDate())
			AND Folder.FolderType IN('BP', 'MP')
		)
		BEGIN

		INSERT INTO tempOrphans (PropertyRSN, PropertyLocation, OrphanedFolderRSN, OrphanedFolderType, OrphanedDate)
		VALUES (@PropertyRSN, @PropertyLocation, @FolderRSN, @FolderType, @FolderDate)
	END

	FETCH NEXT FROM curOrphanFolders INTO @FolderRSN, @FolderType, @PropertyRSN, @PropertyLocation, @FolderDate
END

CLOSE curOrphanFolders
DEALLOCATE curOrphanFolders

DECLARE curApplications CURSOR FOR
SELECT PropertyRSN, OrphanedFolderType
FROM tempOrphans

OPEN curApplications

FETCH NEXT FROM curApplications INTO @PropertyRSN, @FolderType

WHILE @@FETCH_STATUS = 0
	BEGIN

	SELECT @FolderRSN = FolderRSN, @FolderDate = InDate 
	FROM Folder 
	WHERE PropertyRSN = @PropertyRSN 
	AND FolderType = @FolderType 
	AND StatusCode = 30000/*Application*/

	UPDATE tempOrphans
	SET ApplicationRSN = @FolderRSN,
	ApplicationDate = @FolderDate
	WHERE PropertyRSN = @PropertyRSN
	AND OrphanedFolderType = @FolderType

    SET @FolderRSN = NULL
	SET @FolderDate = NULL

	FETCH NEXT FROM curApplications INTO @PropertyRSN, @FolderType
END

CLOSE curApplications
DEALLOCATE curApplications

EXEC usp_AJ_Report 191

--SELECT *
--FROM tempOrphans
--ORDER BY PropertyRSN

TRUNCATE TABLE tempOrphans

END


GO
