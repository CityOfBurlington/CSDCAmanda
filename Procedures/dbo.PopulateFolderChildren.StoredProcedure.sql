USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[PopulateFolderChildren]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure modified to sort the rows while child folders for the given parent folder */

CREATE PROCEDURE  [dbo].[PopulateFolderChildren] (@p_parentRSN INT,@p_lvl INT out)
AS
 DECLARE @v_FolderRSN INT
 DECLARE @v_path VARCHAR(2000)
 DECLARE @v_count INT

BEGIN
	/* 44.29:
	Name of Person: ESS
	Date : March 28 2006
	Version: 4.4.6
	Procedure PopulateFolderChildren is used in AMANDAi for generating the related         Children for Folder Parent RSN
        Modified By ESS On 05-08-2010(Order By Clause Is Added)
	*/
	DECLARE c_crs CURSOR LOCAL FOR
 		SELECT FolderRSN,dbo.f_getRelatedPath(FolderRSN,'Folder') path FROM Folder
						WHERE ParentRSN  = @p_parentRSN AND FolderRSN != @p_parentRSN
						AND Not Exists (Select FolderRSN From #temp_Folder Where FolderRSN = Folder.FolderRSN)
                        ORDER BY Folder.Folderrsn ASC, Folder.FolderCentury ASC, Folder.FolderYear ASC,Folder.FolderSequence ASC, Folder.FolderRevision ASC 
                         
	OPEN c_crs
	FETCH NEXT FROM c_crs INTO @v_FolderRSN,@v_path
	WHILE @@FETCH_STATUS = 0
	BEGIN
		  SET @p_lvl = @p_lvl+1;
		  
		  INSERT INTO #temp_Folder
		  SELECT ParentRSN,FolderRSN,@v_path,@p_lvl,FolderYear,FolderSequence,FolderSection,
		  FolderRevision,FolderName,SubCode,WorkCode,FolderType
		  FROM Folder WHERE FolderRSN = @v_FolderRSN
		  
		  EXEC PopulateFolderChildren @v_FolderRSN,@p_lvl OUT
   	FETCH NEXT FROM c_crs INTO @v_FolderRSN,@v_path
	END

	CLOSE c_crs
	DEALLOCATE c_crs

END


GO
