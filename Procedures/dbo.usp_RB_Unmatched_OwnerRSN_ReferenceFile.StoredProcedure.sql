USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_RB_Unmatched_OwnerRSN_ReferenceFile]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_RB_Unmatched_OwnerRSN_ReferenceFile](@FolderYear CHAR(2))
AS
BEGIN

DECLARE @FolderRSN INT
DECLARE @ReferenceFile VARCHAR(20)
DECLARE @OwnerRSN VARCHAR(20)

CREATE TABLE #Unmatched(
FolderRSN	INT,
OwnerRSN	VARCHAR(20),
ReferenceFile VARCHAR(20)
)

DECLARE curRefNos CURSOR FOR
SELECT Folder.FolderRSN, Folder.ReferenceFile 
FROM Folder
WHERE Folder.FolderType = 'RB'
AND Folder.StatusCode = 1
AND Folder.FolderYear = @FolderYear

OPEN curRefNos

FETCH NEXT FROM curRefNos INTO @FolderRSN, @ReferenceFile

WHILE @@FETCH_STATUS = 0
	BEGIN

	SELECT @OwnerRSN = CAST(ISNULL(FolderPeople.PeopleRSN, 0) AS VARCHAR(20))
	FROM FolderPeople
	WHERE FolderPeople.FolderRSN = @FolderRSN
	AND FolderPeople.PeopleCode = 322

	IF @OwnerRSN <> @ReferenceFile
		BEGIN
		INSERT INTO #Unmatched SELECT @FolderRSN, @OwnerRSN, @ReferenceFile
	END

	SET @OwnerRSN = NULL
	FETCH NEXT FROM curRefNos INTO @FolderRSN, @ReferenceFile
END

CLOSE curRefNos
DEALLOCATE curRefNos

SELECT * 
FROM #Unmatched

DROP TABLE #Unmatched

END
GO
