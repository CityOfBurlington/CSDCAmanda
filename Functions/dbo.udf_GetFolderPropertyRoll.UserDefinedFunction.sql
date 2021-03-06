USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderPropertyRoll]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_GetFolderPropertyRoll](@intFolderRSN INT) RETURNS VARCHAR(20)
AS
BEGIN
DECLARE @strPropertyRoll VARCHAR(20)
SET @strPropertyRoll = ' '
	SELECT @strPropertyRoll = Property.PropertyRoll
	FROM Folder, Property
	WHERE Folder.PropertyRSN = Property.PropertyRSN 
        AND Folder.FolderRSN = @intFolderRSN

RETURN @strPropertyRoll
END


GO
