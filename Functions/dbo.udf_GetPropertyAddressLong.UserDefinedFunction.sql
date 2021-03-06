USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyAddressLong]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPropertyAddressLong](@intFolderRSN INT) 
RETURNS varchar(2000)
AS
BEGIN
	/*	Returns the complete street address spelled out in upper case. Upper case 
		is returned because of incomplete conversion of ValidSteetType to mixed case. */

	DECLARE @varFullAddress varchar(2000)
	DECLARE @varStreet varchar(50)
	DECLARE @varStreetType varchar(20) 

	SELECT	@varStreet = Property.PropStreet, 
			@varStreetType = Property.PropStreetType
	FROM Folder, Property
	WHERE Folder.PropertyRSN = Property.PropertyRSN 
	AND Folder.FolderRSN = @intFolderRSN 

	SET @varFullAddress = ' '

	/*	The following is a work around for ValidStreetTypePropStreetType values 
		which do not have any matches in ValidStreet or Property. They result in 
		the @varStreetAddress lacking StreetType. The workaround is returning 
		Property.PropStreetType when there is no match in ValidStreet. */

	DECLARE @intValidPropStreetTypeCount int

	SELECT @intValidPropStreetTypeCount = COUNT(*)
	FROM Folder, Property, ValidStreetType
	WHERE Property.PropStreetType = ValidStreetType.StreetType 
	AND Folder.PropertyRSN = Property.PropertyRSN 
	AND Folder.FolderRSN = @intFolderRSN 

	IF @intValidPropStreetTypeCount = 0 
	BEGIN
		SELECT @varStreetType = Property.PropStreetType
		FROM Folder, Property
		WHERE Folder.PropertyRSN = Property.PropertyRSN 
		AND Folder.FolderRSN = @intFolderRSN 
	END
	ELSE
	BEGIN
		SELECT @varStreetType = ValidStreetType.StreetTypeDesc
		FROM Folder, Property, ValidStreetType
		WHERE Property.PropStreetType = ValidStreetType.StreetType 
		AND Folder.PropertyRSN = Property.PropertyRSN 
		AND Folder.FolderRSN = @intFolderRSN 
	END

	SELECT @varFullAddress = RTRIM(ISNULL(Property.PropHouse, '') + ' ' + 
		ISNULL(@varStreet, '') + ' ' + 
		ISNULL(@varStreetType, '') + ' ' + 
		ISNULL(Property.PropUnitType, '') + ' ' + 
		ISNULL(Property.PropUnit, ''))
	FROM Property, Folder
	WHERE Folder.PropertyRSN = Property.PropertyRSN
	AND Folder.FolderRSN = @intFolderRSN 

/*	SELECT @varFullAddress = RTRIM(ISNULL(Property.PropHouse, '') + ' ' + 
		ISNULL(Property.PropStreetUpper, '') + ' ' + 
		ISNULL(ValidStreetType.StreetTypeDesc, '') + ' ' + 
		ISNULL(Property.PropUnitType, '') + ' ' + 
		ISNULL(Property.PropUnit, ''))
	FROM Property, Folder, ValidStreetType
	WHERE Folder.PropertyRSN = Property.PropertyRSN
	AND Property.PropStreettype *= ValidStreetType.StreetType
	AND Folder.FolderRSN = @intFolderRSN  */

	RETURN UPPER(@varFullAddress)
END

GO
