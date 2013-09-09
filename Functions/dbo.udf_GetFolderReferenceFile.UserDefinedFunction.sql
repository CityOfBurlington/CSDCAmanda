USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderReferenceFile]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetFolderReferenceFile](@intFolderRSN INT) RETURNS VARCHAR(20)
AS
BEGIN
DECLARE @strRefFileNo VARCHAR(20)
SET @strRefFileNo = ' '
	SELECT @strRefFileNo = Folder.ReferenceFile
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

RETURN @strRefFileNo
END


GO
