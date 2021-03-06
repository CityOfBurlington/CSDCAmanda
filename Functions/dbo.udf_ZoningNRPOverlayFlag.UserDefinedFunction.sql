USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningNRPOverlayFlag]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZoningNRPOverlayFlag](@intFolderRSN INT)
RETURNS varchar(2)
AS
BEGIN
	/* Returns 'Y' if Natural Resource Protection (NRP) overlay district 
		is applicable, and 'N' if it is not. */

	DECLARE @varFloodHazardValue varchar(10)	/* 85 */
	DECLARE @varWetlandValue varchar(10)		/* 90 */
	DECLARE @varNaturalAreaValue varchar(30)	/* 95 */
	DECLARE @varRiparianValue varchar(10)		/* 124 */
	DECLARE @varVernalPoolValue varchar(20)		/* 129 */
	DECLARE @varNRPFlag varchar(2)

	SET @varNRPFlag = 'N'
	
	SELECT @varFloodHazardValue = PropertyInfo.PropInfoValue
	FROM Folder, PropertyInfo 
	WHERE Folder.FolderRSN = @intFolderRSN 
	AND Folder.FolderType LIKE 'Z%' 
	AND Folder.PropertyRSN = PropertyInfo.PropertyRSN 
	AND PropertyInfo.PropertyInfoCode = 85 

	SELECT @varWetlandValue = PropertyInfo.PropInfoValue
	FROM Folder, PropertyInfo 
	WHERE Folder.FolderRSN = @intFolderRSN 
	AND Folder.FolderType LIKE 'Z%' 
	AND Folder.PropertyRSN = PropertyInfo.PropertyRSN 
	AND PropertyInfo.PropertyInfoCode = 90

	SELECT @varNaturalAreaValue = PropertyInfo.PropInfoValue
	FROM Folder, PropertyInfo 
	WHERE Folder.FolderRSN = @intFolderRSN 
	AND Folder.FolderType LIKE 'Z%' 
	AND Folder.PropertyRSN = PropertyInfo.PropertyRSN 
	AND PropertyInfo.PropertyInfoCode = 95  

	SELECT @varRiparianValue = PropertyInfo.PropInfoValue
	FROM Folder, PropertyInfo 
	WHERE Folder.FolderRSN = @intFolderRSN 
	AND Folder.FolderType LIKE 'Z%' 
	AND Folder.PropertyRSN = PropertyInfo.PropertyRSN 
	AND PropertyInfo.PropertyInfoCode = 124  
	
	SELECT @varVernalPoolValue = PropertyInfo.PropInfoValue
	FROM Folder, PropertyInfo 
	WHERE Folder.FolderRSN = @intFolderRSN 
	AND Folder.FolderType LIKE 'Z%' 
	AND Folder.PropertyRSN = PropertyInfo.PropertyRSN 
	AND PropertyInfo.PropertyInfoCode = 129 

	IF @varFloodHazardValue IS NOT NULL SELECT @varNRPFlag = 'Y'
	IF @varWetlandValue IS NOT NULL SELECT @varNRPFlag = 'Y'
	IF @varNaturalAreaValue IS NOT NULL SELECT @varNRPFlag = 'Y'
	IF @varRiparianValue IS NOT NULL SELECT @varNRPFlag = 'Y'
	IF @varVernalPoolValue IS NOT NULL SELECT @varNRPFlag = 'Y'

	RETURN @varNRPFlag 
END



GO
