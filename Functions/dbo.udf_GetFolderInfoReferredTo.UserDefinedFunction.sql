USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderInfoReferredTo]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderInfoReferredTo](@intFolderRSN int) RETURNS varchar(30)
AS
BEGIN
   DECLARE @strReferredTo varchar(30)
   SET @strReferredTo = ' '

   SELECT @strReferredTo = FolderInfo.InfoValue
	FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @intFolderRSN
      AND FolderInfo.InfoCode = 31010

   RETURN @strReferredTo
END


GO
