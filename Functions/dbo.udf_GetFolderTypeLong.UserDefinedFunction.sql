USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderTypeLong]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    Function [dbo].[udf_GetFolderTypeLong](@intFolderRSN int) 
RETURNS varchar(50)
AS
BEGIN
   DECLARE @strFolderPermitType varchar(50)
   DECLARE @strFolderType varchar(3)

   SELECT @strFolderPermitType = ValidFolder.FolderDesc
      FROM Folder, ValidFolder
     WHERE Folder.Foldertype = ValidFolder.FolderType
       AND Folder.FolderRSN = @intFolderRSN

RETURN @strFolderPermitType
END


GO
