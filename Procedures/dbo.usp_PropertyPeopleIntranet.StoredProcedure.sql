USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_PropertyPeopleIntranet]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_PropertyPeopleIntranet] (@ParcelID VARCHAR(13)) 
AS
BEGIN

DECLARE @PropertyRSN INT

SELECT @PropertyRSN = PropertyRSN
FROM Property
WHERE PropertyRoll = @ParcelID

SELECT 1  AS SortOrder,
'Owner' AS Person,
People.NameLast, 
People.NameFirst, 
People.OrganizationName,
CASE WHEN People.Phone1 = '8020000000' THEN '' ELSE dbo.udf_FormatPhoneNumber(People.Phone1) END AS Phone1, 
CASE WHEN People.Phone2 = '8020000000' THEN '' ELSE dbo.udf_FormatPhoneNumber(People.Phone2) END AS Phone2, 
People.AddressLine1,
People.AddressLine2,
People.AddressLine3,
People.AddressLine4
FROM Property
INNER JOIN PropertyPeople ON Property.PropertyRSN = PropertyPeople.PropertyRSN
INNER JOIN People ON PropertyPeople.PeopleRSN = People.PeopleRSN
WHERE PropertyPeople.PeopleCode = 2 /*Owner*/
AND Property.PropertyRSN = @PropertyRSN

UNION

SELECT 2 AS SortOrder,
'Prop Mgr' AS Person,
People.NameLast, 
People.NameFirst, 
People.OrganizationName,
CASE WHEN People.Phone1 = '8020000000' THEN '' ELSE dbo.udf_FormatPhoneNumber(People.Phone1) END AS Phone1, 
CASE WHEN People.Phone2 = '8020000000' THEN '' ELSE dbo.udf_FormatPhoneNumber(People.Phone2) END AS Phone2, 
People.AddressLine1,
People.AddressLine2,
People.AddressLine3,
People.AddressLine4
FROM People
INNER JOIN FolderPeople ON People.PeopleRSN = FolderPeople.PeopleRSN
INNER JOIN Folder ON FolderPeople.FolderRSN = Folder.FolderRSN
INNER JOIN FolderProperty ON Folder.FolderRSN = FolderProperty.FolderRSN
WHERE FolderPeople.PeopleCode = 75 /*Property Manager*/
AND Folder.FolderType = 'RB'
AND Folder.PropertyRSN = @PropertyRSN
AND Folder.FolderRSN = (SELECT MAX(FolderRSN) FROM Folder WHERE FolderType = 'RB' AND PropertyRSN = @PropertyRSN)
AND Folder.StatusCode <> 2 /*Closed*/
AND ISNULL(dbo.f_info_numeric_property(@PropertyRSN, 20), 0) > 0

UNION

SELECT 3 AS SortOrder,
'Emgcy Contact' AS Person,
People.NameLast, People.NameFirst, People.OrganizationName,
CASE WHEN People.Phone1 = '8020000000' THEN '' ELSE dbo.udf_FormatPhoneNumber(People.Phone1) END AS Phone1, 
CASE WHEN People.Phone2 = '8020000000' THEN '' ELSE dbo.udf_FormatPhoneNumber(People.Phone2) END AS Phone2, 
People.AddressLine1,
People.AddressLine2,
People.AddressLine3,
People.AddressLine4
FROM People 
INNER JOIN FolderPeople ON People.PeopleRSN = FolderPeople.PeopleRSN
INNER JOIN Folder ON FolderPeople.FolderRSN = Folder.FolderRSN
INNER JOIN FolderProperty ON Folder.FolderRSN = FolderProperty.FolderRSN
WHERE FolderPeople.PeopleCode = 80 /*Emergency Contact*/
AND Folder.FolderType = 'RB'
AND Folder.PropertyRSN = @PropertyRSN
AND Folder.FolderRSN = (SELECT MAX(FolderRSN) FROM Folder WHERE FolderType = 'RB' AND PropertyRSN = @PropertyRSN)
AND Folder.StatusCode <> 2 /*Closed*/
AND ISNULL(dbo.f_info_numeric_property(@PropertyRSN, 20), 0) > 0

END


GO
