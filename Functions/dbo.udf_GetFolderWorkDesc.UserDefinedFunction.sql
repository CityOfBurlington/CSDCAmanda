USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderWorkDesc]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderWorkDesc](@intFolderRSN INT)
RETURNS varchar(100)
AS 
BEGIN
   DECLARE @varWorkDesc varchar(100)

   SELECT @varWorkDesc = ValidWork.WorkDesc
     FROM ValidWork, Folder
    WHERE Folder.WorkCode = ValidWork.WorkCode
      AND Folder.FolderRSN = @intFolderRSN

   RETURN @varWorkDesc
END

GO
