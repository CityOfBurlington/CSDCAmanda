USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_RB_Owner_Name_Match]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_RB_Owner_Name_Match](@FolderYear CHAR(2)) 
AS
BEGIN
	SELECT 
	dbo.udf_GetPropertyAddress(Folder.PropertyRSN) AS PropertyAddress,
	UPPER(dbo.udf_GetPeopleLastName(FolderPeople.PeopleRSN)) AS PCO_LastName,
	UPPER(dbo.udf_GetPropertyPeopleLastName(Folder.PropertyRSN, 2)) AS OwnerLastName
	FROM Folder 
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN Property ON Folder.PropertyRSN = Property.PropertyRSN
	AND Folder.FolderType = 'RB'
	AND Folder.FolderYear = @FolderYear
	AND FolderPeople.PeopleCode = 322 /*Primary Code Owner*/
	AND LTRIM(RTRIM(dbo.udf_GetPeopleLastName(FolderPeople.PeopleRSN))) <> LTRIM(RTRIM(dbo.udf_GetPropertyPeopleLastName(Folder.PropertyRSN, 2)))
	ORDER BY Property.PropStreet, Property.PropStreetType, Property.PropHouseNumeric, Property.PropUnit
END


GO
