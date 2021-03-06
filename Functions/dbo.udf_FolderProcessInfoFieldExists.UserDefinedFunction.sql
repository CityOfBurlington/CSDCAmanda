USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_FolderProcessInfoFieldExists]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_FolderProcessInfoFieldExists](@intProcessRSN int, @intInfoCode int) 
RETURNS INT
AS
BEGIN
   DECLARE @intFieldCount int

   SET @intFieldCount = 0   /* Process Info field does not exist */

   SELECT @intFieldCount = COUNT(*)
     FROM FolderProcessInfo
    WHERE FolderProcessInfo.ProcessRSN = @intProcessRSN
      AND FolderProcessInfo.InfoCode = @intInfoCode

   RETURN @intFieldCount
END


GO
