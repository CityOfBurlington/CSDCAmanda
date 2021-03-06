USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[GetFolderRelatedView]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure GetFolderRelatedView modified to add alias name in the label for folder related view */

CREATE PROCEDURE [dbo].[GetFolderRelatedView] @FolderRSN INT, @UserId VARCHAR(128)
AS
	DECLARE @v_startRSN INT    
	DECLARE @v_currentRSN INT
	DECLARE @v_lvl INT
	DECLARE @noDataFound CHAR(1)
    DECLARE @v_ExistRSN INT
BEGIN
	/*
	Name of Person: ESS
	Date : March 28 2006
	Version: 4.4.4.6

	Procedure GetFolderRelatedView is used in AMANDAi to get Related view structure for a specific FolderRSN
	ESS Modified Nov 05 2008:Related view node click fixing in MS Sql Server DataBase.
	*/
	/* ESS Modified 2008.10.27 - Modified the Select Clause (from #temp_Folder Folder, ValidFolder, ValidFolderGroup) to return SubCode and WorkCode   */
	/* ESS Modified 2008.11.05 - Server hang problem during deleting a child folder in Related view*/
	/* ESS Modified 2008.12.05 - Used F_Relatedview_label_folder function*/
	/* ESS Modified 2011.02.17 - Fixed issue id :21117 (return folderType from #temp_folder)*/
	/* 5.4.4.30: ESS Modified 2011.03.08 - Issue id :21255 (Alias name added for F_Relatedview_label_folder)*/
	
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
	WHILE (@v_currentRSN IS NOT NULL)
	BEGIN
		SET @v_startRSN = @v_currentRSN		
		Select @v_currentRSN = CASE ParentRSN
					WHEN FolderRSN THEN
						NULL
					WHEN @FolderRSN THEN
						NULL
					ELSE
						ParentRSN
					END
		From Folder Where FolderRSN = @v_currentRSN
		if @@rowcount = 0 		
			begin
				if @v_currentRSN = @FolderRSN				
					begin
						set @noDataFound = 'Y'
					end
				else
					begin
						SET @v_startRSN = @v_ExistRSN				
					end
				set @v_currentRSN = null
                
			end
		else
			begin
				SET @v_ExistRSN = @v_startRSN	
			end
	END

	
	if @noDataFound = 'N'
		begin
			SET @v_lvl = 1
			INSERT INTO #temp_Folder
			SELECT ParentRSN,FolderRSN,FolderRSN,@v_lvl,FolderYear,FolderSequence,FolderSection,
				FolderRevision,FolderName,SubCode,WorkCode,FolderType
			FROM Folder WHERE FolderRSN = @v_startRSN
			
			EXEC PopulateFolderChildren @v_startRSN, @v_lvl OUT
		end
	
	SELECT Path, FolderRSN, GroupTypeCode, FolderYear, FolderSequence, FolderSection, FolderRevision, FolderName, SubCode, 
		WorkCode , FolderDesc, TabMask, ViolationFlag, dbo.F_Relatedview_label_folder(FolderRSN) LabelFolder,Folder.FolderType FolderType
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
