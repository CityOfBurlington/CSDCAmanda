USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[GetFolderChildrenView]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[GetFolderChildrenView] @FolderRSN INT, @UserId VARCHAR(128)
AS

/* Amanda 44.25:
Name of Person: ESS
Date : Dec 18, 2008
Version: 

Procedure GetFolderChildrenView is used in AMANDAi to get Related view structure for a specific FolderRSN
*/

	DECLARE @v_startRSN INT    
	DECLARE @v_currentRSN INT
	DECLARE @v_lvl INT
	DECLARE @noDataFound CHAR(1)
    DECLARE @v_ExistRSN INT
BEGIN
	CREATE TABLE #temp_Folder
		(
		ParentRSN       INT   	      ,
		FolderRSN       INT	      ,
		Path            VARCHAR(2000) ,
		Rowndx          INT           ,
		FolderYear      VARCHAR(4)    ,
		FolderSequence  VARCHAR(10 )  ,
		FolderSection   VARCHAR(3 )   ,
		FolderRevision  VARCHAR(3 )   ,
		FolderName      VARCHAR(80)   ,
		SubCode         INT           ,
		WorkCode        INT           ,
		FolderType      VARCHAR(4)
		)
	SET @noDataFound = 'N'
	SET @v_currentRSN = @FolderRSN;
	
	if @noDataFound = 'N'
		begin
			SET @v_lvl = 1
			INSERT INTO #temp_Folder
			SELECT ParentRSN,FolderRSN,FolderRSN,@v_lvl,FolderYear,FolderSequence,FolderSection,
				FolderRevision,FolderName,SubCode,WorkCode,FolderType
			FROM Folder WHERE FolderRSN = @v_currentRSN
			
			EXEC PopulateFolderChildren @v_currentRSN, @v_lvl OUT
		end
	
	SELECT Path, FolderRSN, GroupTypeCode, FolderYear, FolderSequence, FolderSection, FolderRevision,
		FolderName, SubCode,
		WorkCode , FolderDesc, TabMask, ViolationFlag, dbo.F_Relatedview_label_folder(FolderRSN)
	FROM #temp_Folder Folder, ValidFolder, ValidFolderGroup
	WHERE ValidFolderGroup.FolderGroupCode = ValidFolder.FolderGroupCode
	AND ( ValidFolder.ConfidentialFolder is NULL OR ValidFolder.ConfidentialFolder = 'N'
	OR ( ValidFolder.ConfidentialFolder = 'Y'
	AND EXISTS ( SELECT * FROM ValidUserButton WHERE ValidUserButton.UserId = @UserId
	AND ValidUserButton.FolderType = ValidFolder.FolderType AND ValidUserButton.ButtonCode = 9 )))
	AND ValidFolder.FolderType = Folder.FolderType
	ORDER BY ROWNDX
END

GO
