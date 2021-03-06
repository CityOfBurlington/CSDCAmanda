USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Report_Permits_By_Property]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Report_Permits_By_Property](@varPropertyRSNList varchar(100))
AS
BEGIN
	/*	Creates a list of zoning permits for specified properties, using a temporary table.
		@varPropertyRSNList values must be comma-separated. 
		Place PropertyRSN comma-separated value list within single quotes, e.g. 
		EXECUTE dbo.usp_Zoning_Report_Permits_By_Property '4053, 3601, 3605, 3602' */
	
	DECLARE @intPosition int
	
	CREATE TABLE #PropertyRSNList ( PropertyRSN int )

	--add comma to end of list
	SET @varPropertyRSNList = @varPropertyRSNList + ','

	--loop through list
	WHILE CHARINDEX(',', @varPropertyRSNList) > 0
	BEGIN
		--get next comma position
		SET @intPosition = CHARINDEX(',', @varPropertyRSNList)

		--insert next value into table
		INSERT #PropertyRSNList VALUES (LTRIM(RTRIM(LEFT(@varPropertyRSNList, @intPosition - 1))))

		--delete inserted value from list
		SET @varPropertyRSNList = STUFF(@varPropertyRSNList, 1, @intPosition, '')
	END

	SELECT Folder.FolderRSN, 
	dbo.udf_GetFirstPropertyOwner(Folder.PropertyRSN)AS OwnerName, 
	dbo.udf_GetPropertyAddressLongMixed(Folder.FolderRSN) AS Address, 
	Property.PropertyName AS CommonName, 
	ValidFolder.FolderDesc AS PermitType, 
	Folder.ReferenceFile AS ZPNumber, 
	CONVERT(CHAR(11), Folder.IssueDate) AS DecisionDate, 
	CONVERT(CHAR(11), dbo.f_info_date(Folder.FolderRSN, 10024)) AS PermitExpiryDate, 
	dbo.udf_GetZoningFeesFolderDue(Folder.FolderRSN) AS PermitFeesDue, 
	( dbo.udf_GetZoningFeeCalcFinalCO(Folder.FolderRSN) + dbo.udf_GetZoningFeeCalcFinalCOFilingFee(Folder.FolderRSN) ) AS COFee, 
	dbo.udf_GetZoningFeeCalcFinalCOAfterTheFact(Folder.FolderRSN) AS ATFFee, 
	ValidStatus.StatusDesc AS Status, Folder.FolderDescription AS Description 
	FROM Folder, ValidFolder, ValidStatus, Property, #PropertyRSNList
	WHERE Folder.FolderType LIKE 'Z%' 
	AND Folder.PropertyRSN = Property.PropertyRSN 
	AND Property.PropertyRSN = #PropertyRSNList.PropertyRSN 
	AND Folder.StatusCode = ValidStatus.StatusCode 
	AND Folder.FolderType = ValidFolder.FolderType 
	ORDER BY Property.PropStreet, Property.PropStreetType, Property.PropHouseNumeric, Property.PropUnit, Folder.InDate 

END
GO
