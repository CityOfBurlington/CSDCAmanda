USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetInspectorAssigned]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetInspectorAssigned](@intFolderRSN int) RETURNS varchar(30)
AS
BEGIN
   DECLARE @strInspector varchar(30)
   SET @strInspector = ' '

   SELECT @strInspector = FolderInfo.InfoValue 
      FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @intFolderRSN
      AND FolderInfo.InfoCode = 20009

   RETURN @strInspector
END


GO
