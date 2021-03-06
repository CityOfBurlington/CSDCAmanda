USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[GetConditionRelatedView]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[GetConditionRelatedView] @ConditionRSN INT, @Table VARCHAR(100)
AS

/* Amanda 44.25:
Name of Person: ESS
Date : Dec 18, 2008
Version:
Procedure GetConditionRelatedView is used in AMANDAi for getting the Condition Cascade Related View in a format same as Oracle.
*/

BEGIN
    IF(@Table='Folder')
    BEGIN     
		Select f.path, f.ConditionRSN, f.SourceFolderRSN, Folder.FolderRSN, isnull(Folder.FolderName,'') FolderName, 
			   isnull(Folder.ParentRSN,'') ParentRSN,Folder.PropertyRSN 
		from Folder, (Select FolderRSN, ConditionRSN, isnull(SourceFolderRSN,'') SourceFolderRSN, 
							 dbo.f_getConditionRelatedPath(FolderRSN,ConditionRSN,'Folder') path 
					  from FolderCondition
					  Where ConditionRSN = @ConditionRSN ) f 
		where Folder.FolderRSN = f.FolderRSN
		Order by f.path
    END
    ELSE IF(@Table='Property')
    BEGIN 
		Select isnull(Property.ParentPropertyRSN,'') ParentPropertyRSN, p.path, 
			   isnull(Property.PropertyName,'') PropertyName
		from Property,(Select PropertyRSN, dbo.f_getConditionRelatedPath(PropertyRSN,ConditionRSN,'Property') path 
					   from PropertyCondition Where ConditionRSN = @ConditionRSN ) p 
		where Property.PropertyRSN = p.PropertyRSN
		Order by p.path 
    END   
END

GO
