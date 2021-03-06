USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderSubDesc]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderSubDesc](@intFolderRSN INT)
RETURNS varchar(100)
AS 
BEGIN
   DECLARE @varSubDesc varchar(100)

   SELECT @varSubDesc = ValidSub.SubDesc
     FROM ValidSub, Folder
    WHERE Folder.SubCode = ValidSub.SubCode
      AND Folder.FolderRSN = @intFolderRSN

   RETURN @varSubDesc
END

GO
