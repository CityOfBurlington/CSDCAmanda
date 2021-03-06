USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderInfoDateLong]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_GetFolderInfoDateLong](@intInfoCode int, @intFolderRSN int) RETURNS varchar(30)
AS
BEGIN
   DECLARE @strDateLong varchar(30)
   SET @strDateLong = ' '

   SELECT @strDateLong = RTRIM(DATENAME(MONTH, FolderInfo.InfoValueDateTime) + ' ' + DATENAME(DAY, FolderInfo.InfoValueDateTime) + ', ' + DATENAME(YEAR, FolderInfo.InfoValueDateTime))
      FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @intFolderRSN
      AND FolderInfo.InfoCode = @intInfoCode

   RETURN @strDateLong
END


GO
