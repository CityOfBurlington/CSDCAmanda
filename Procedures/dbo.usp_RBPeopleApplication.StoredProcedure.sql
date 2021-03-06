USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_RBPeopleApplication]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_RBPeopleApplication](@strFolderType varchar(2), @strPeopleRSN varchar(10))
AS
BEGIN
	SELECT people.PeopleRSN, 
		folderpeople.peoplecode,
		RegLookupTable.SortOrder,
		People.NameFirst, 
		People.NameLast, 
		People.OrganizationName,
		People.AddressLine1, 
		People.AddressLine2, 
		People.AddressLine3,
		People.Phone1, 
		People.Phone1Desc, 
		People.Phone2,
		People.Phone2Desc, 
		people.emailaddress,
		dbo.f_info_alpha_People(People.PeopleRSN,20) as DOB,
		dbo.f_info_alpha_People(People.PeopleRSN,25)as Military, 
		peopletext,
		formtext1, formtext2, folder.referencefile as OwnerID, 
		RegLookupTable.DateofBirth,  
		Count(folder.FolderRSN) as NoofRentalProps
	FROM Folder Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
	INNER JOIN RegLookupTable ON FolderPeople.PeopleCode = RegLookupTable.PeopleCode
	WHERE Folder.FolderType = @strFolderType
		AND Folder.ReferenceFile = @strPeopleRSN
	GROUP BY people.PeopleRSN, 
		folderpeople.peoplecode,
		SortOrder,People.NameFirst, 
		People.NameLast, 
		People.OrganizationName,
		People.AddressLine1, 
		People.AddressLine2, 
		People.AddressLine3,
		People.Phone1, 
		People.Phone1Desc, 
		People.Phone2,
		People.Phone2Desc, 
		people.emailaddress,
		dbo.f_info_alpha_People(People.PeopleRSN,20),
		dbo.f_info_alpha_People(People.PeopleRSN,25), 
		peopletext,
		formtext1, 
		formtext2, 
		folder.referencefile, 
		RegLookupTable.DateofBirth
	ORDER BY Count(Folder.FolderRSN) DESC,
	Reglookuptable.sortorder

END



GO
