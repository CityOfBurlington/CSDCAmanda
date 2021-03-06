USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderInfoFollowup]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderInfoFollowup](@intFolderRSN int) RETURNS varchar(30)
AS
BEGIN
   DECLARE @strFollowup varchar(30)
   SET @strFollowup = ' '

   SELECT @strFollowup = FolderInfo.InfoValue
	FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @intFolderRSN
      AND FolderInfo.InfoCode = 31050

   RETURN @strFollowup
END


GO
