USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetStreetIDNumberFromFolder]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetStreetIDNumberFromFolder](@intFolderRSN INT) 
RETURNS INT
AS
BEGIN
	DECLARE @intStreetNumber int

	SET @intStreetNumber = 0

	SELECT @intStreetNumber = ValidStreet.StreetNumber
	FROM Property, ValidStreet 
	WHERE Property.PropStreet = ValidStreet.PropStreet
	AND Property.PropStreetType = ValidStreet.PropStreetType
	AND Property.PropertyRSN = ( 
		SELECT Folder.PropertyRSN
		FROM Folder 
		WHERE Folder.FolderRSN = @intFolderRSN )

	RETURN @intStreetNumber
END

GO
