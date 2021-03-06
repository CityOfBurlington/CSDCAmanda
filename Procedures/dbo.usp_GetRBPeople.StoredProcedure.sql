USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetRBPeople]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_GetRBPeople](@pstrReferenceFile VARCHAR(8))
AS
/*Primary Contact - Based on Folder.ReferenceFile*/
SELECT 1 AS SortOrder, 'Primary Contact' AS PeopleDesc, People.NameFirst, People.NameLast, People.OrganizationName,
People.AddressLine1, People.AddressLine2, People.AddressLine3,
People.BirthDate, People.Phone1, People.Phone2, People.EmailAddress,
People.PeopleRSN
FROM People
WHERE PeopleRSN = @pstrReferenceFile 

UNION

/*Additional Owners - Based on FolderPeople.PeopleCode = 2 AND PeopleRSN <> Folder.ReferenceFile*/
SELECT DISTINCT 2 AS SortOrder, 'Additional Owner' AS PeopleDesc, People.NameFirst, People.NameLast, People.OrganizationName,
People.AddressLine1, People.AddressLine2, People.AddressLine3,
People.BirthDate, People.Phone1, People.Phone2, People.EmailAddress,
People.PeopleRSN
FROM People
INNER JOIN FolderPeople ON People.PeopleRSN = FolderPeople.PeopleRSN
INNER JOIN Folder ON FolderPeople.FolderRSN = Folder.FolderRSN
WHERE Folder.ReferenceFile = @pstrReferenceFile 
AND FolderPeople.PeopleCode = 125 /*Code Owner*/
AND FolderPeople.PeopleRSN <> @pstrReferenceFile 
AND Folder.StatusCode <> 2

UNION

/*Emergency Contact - Based on FolderPeople.PeopleCode = 80*/
SELECT DISTINCT 3 AS SortOrder, 'Emergency Contact' AS PeopleDesc, People.NameFirst, People.NameLast, People.OrganizationName,
People.AddressLine1, People.AddressLine2, People.AddressLine3,
People.BirthDate, People.Phone1, People.Phone2, People.EmailAddress,
People.PeopleRSN
FROM People
INNER JOIN FolderPeople ON People.PeopleRSN = FolderPeople.PeopleRSN
INNER JOIN Folder ON FolderPeople.FolderRSN = Folder.FolderRSN
WHERE Folder.ReferenceFile = @pstrReferenceFile 
AND FolderPeople.PeopleCode = 80 /*Emergency Contact*/
AND Folder.StatusCode <> 2

UNION

/*Emergency Contact - Based on FolderPeople.PeopleCode = 80*/
SELECT DISTINCT 4 AS SortOrder, 'Property Manager' AS PeopleDesc, People.NameFirst, People.NameLast, People.OrganizationName,
People.AddressLine1, People.AddressLine2, People.AddressLine3,
People.BirthDate, People.Phone1, People.Phone2, People.EmailAddress,
People.PeopleRSN
FROM People
INNER JOIN FolderPeople ON People.PeopleRSN = FolderPeople.PeopleRSN
INNER JOIN Folder ON FolderPeople.FolderRSN = Folder.FolderRSN
WHERE Folder.ReferenceFile = @pstrReferenceFile 
AND FolderPeople.PeopleCode = 75 /*Property Manager*/
AND Folder.StatusCode <> 2

UNION

/*Emergency Contact - Based on FolderPeople.PeopleCode = 80*/
SELECT DISTINCT 5 AS SortOrder, 'Service of Process' AS PeopleDesc, People.NameFirst, People.NameLast, People.OrganizationName,
People.AddressLine1, People.AddressLine2, People.AddressLine3,
People.BirthDate, People.Phone1, People.Phone2, People.EmailAddress,
People.PeopleRSN
FROM People
INNER JOIN FolderPeople ON People.PeopleRSN = FolderPeople.PeopleRSN
INNER JOIN Folder ON FolderPeople.FolderRSN = Folder.FolderRSN
WHERE Folder.ReferenceFile = @pstrReferenceFile 
AND FolderPeople.PeopleCode = 85 /*Service of Process*/
AND Folder.StatusCode <> 2




GO
