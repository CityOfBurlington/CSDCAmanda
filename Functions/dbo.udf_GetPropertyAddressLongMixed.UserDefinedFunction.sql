USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyAddressLongMixed]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetPropertyAddressLongMixed](@intFolderRSN INT) 
RETURNS VARCHAR(2000)
AS
BEGIN
   DECLARE @strFullAddress VARCHAR(2000) 

   SET @strFullAddress = ' '

   SELECT @strFullAddress = RTRIM(ISNULL(Property.PropHouse, '') + ' ' + 
          ISNULL(Property.PropStreet, '') + ' ' + 
          ISNULL(ValidStreetType.StreetTypeDesc, '') + ' ' + 
          ISNULL(Property.PropUnitType, '') + ' ' + 
          ISNULL(Property.PropUnit, ''))
     FROM Property, Folder, ValidStreetType
    WHERE Folder.PropertyRSN = Property.PropertyRSN
      AND Property.PropStreettype *= ValidStreetType.StreetType
      AND Folder.FolderRSN = @intFolderRSN

    RETURN @strFullAddress 
END


GO
