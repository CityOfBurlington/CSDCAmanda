USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderType]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    Function [dbo].[udf_GetFolderType](@intFolderRSN int) 
RETURNS varchar(50)
AS
BEGIN
   DECLARE @strFolderPermitType varchar(50)
   DECLARE @strFolderType varchar(4)

   SELECT @strFolderType = Folder.FolderType
      FROM Folder
     WHERE Folder.FolderRSN = @intFolderRSN

RETURN @strFolderType
END


GO
