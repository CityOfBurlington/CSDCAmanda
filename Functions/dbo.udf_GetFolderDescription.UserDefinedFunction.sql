USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderDescription]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetFolderDescription](@intFolderRSN INT) RETURNS VARCHAR(2000)
AS
BEGIN
DECLARE @strDescription VARCHAR(2000)
SET @strDescription = ' '
	SELECT @strDescription = Folder.FolderDescription
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

RETURN @strDescription
END

GO
