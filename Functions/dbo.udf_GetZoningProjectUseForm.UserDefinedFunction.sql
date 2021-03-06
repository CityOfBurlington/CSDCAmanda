USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningProjectUseForm]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningProjectUseForm](@intFolderRSN INT) 
RETURNS varchar(100) 
AS
BEGIN
   /* Used by Infomaker permit forms */
   DECLARE @varProjectUseType varchar(100) 
   DECLARE @varFolderType varchar(4)
   DECLARE @intWorkCode int 
   DECLARE @varWorkDesc varchar(30)
   DECLARE @varProjUse varchar(20)
   DECLARE @varProjType varchar(40) 
   DECLARE @varDescrip varchar(30)
  
   SELECT @varFoldertype = Folder.FolderType, 
          @intWorkCode = Folder.WorkCode, 
          @varWorkDesc = ValidWork.WorkDesc
     FROM Folder, ValidWork  
    WHERE Folder.FolderRSN = @intFolderRSN  
      AND Folder.WorkCode = ValidWork.WorkCode 

   SELECT @varProjUse = ISNULL(dbo.f_info_alpha_null(@intFolderRSN, 10019), 'Unknown Use')
 
   IF @varFolderType = 'Z3'
      SELECT @varProjType = ISNULL(dbo.f_info_alpha_null(@intFolderRSN, 10015), 'Unknown Type') 
   IF @varFolderType IN ('ZD', 'ZN') 
      SELECT @varProjType = ISNULL(@varWorkDesc, 'Unknown WorkCode')
   IF @varFolderType NOT IN ('Z3', 'ZD', 'ZN')
      SELECT @varProjType = ISNULL(dbo.f_info_alpha_null(@intFolderRSN, 10021), 'Unknown Type') 

   IF @varFolderType IN ('ZD', 'ZN') SELECT @varDescrip = 'Determination Type: '
   ELSE SELECT @varDescrip = 'Project Type: '

   SELECT @varProjectUseType = @varDescrip + @varProjUse + ' - ' + @varProjType

   RETURN @varProjectUseType 
END

GO
