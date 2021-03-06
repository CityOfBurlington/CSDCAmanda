USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_FolderInfoFieldExists]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_FolderInfoFieldExists](@intFolderRSN int, @intInfoCode int) 
RETURNS INT
AS
BEGIN
   DECLARE @intFieldCount int

   SET @intFieldCount = 0   /* Info field does not exist */

   SELECT @intFieldCount = COUNT(*)
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @intFolderRSN
      AND FolderInfo.InfoCode = @intInfoCode

   RETURN @intFieldCount
END


GO
