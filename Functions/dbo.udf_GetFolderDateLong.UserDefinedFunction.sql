USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderDateLong]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetFolderDateLong](@strFolderDate varchar(50), @intFolderRSN int) RETURNS varchar(30)
AS
BEGIN
   DECLARE @strDateLong varchar(30)
   SET @strDateLong = ' '

   SELECT @strDateLong = RTRIM(DATENAME(MONTH, @strFolderDate) + ' ' + DATENAME(DAY, @strFolderDate) + ', ' + DATENAME(YEAR, @strFolderDate))
      FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   RETURN @strDateLong
END


GO
