USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_MH_InspectionDueLetter]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_MH_InspectionDueLetter](@FolderRSN INT, @PeopleRSN INT) AS
BEGIN
	SELECT TOP 1 Folder.FolderRSN, dbo.udf_GetInspectionRequestLetterDays(Folder.FolderRSN) AS DaysToReply,
	Folder.FolderName, Folder.IssueUser, dbo.f_info_numeric_property(Folder.PropertyRSN, 15) AS NumResUnits,
	ValidUser.UserName, ValidUser.UserPhone, ValidUser.EmailAddress,
	ValidUser.UserTitle, 
	ISNULL(People.OrganizationName, '') AS OrganizationName,
	ISNULL(People.NameFirst, '') AS NameFirst,
	ISNULL(People.NameLast, '') AS NameLast,
	ISNULL(People.AddressLine1, '') AS AddressLine1, 
	ISNULL(People.AddressLine2, '') AS AddressLine2, 
	ISNULL(People.AddressLine3, '') AS AddressLine3,
	tblSignatures.SignatureBlob, dbo.FormatDateTime(Folder.InDate, 'LONGDATE') AS IssueDate
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
	LEFT OUTER JOIN FolderInfo ON Folder.FolderRSN = FolderInfo.FolderRSN AND FolderInfo.InfoCode = 4020
	LEFT OUTER JOIN ValidUser ON FolderInfo.InfoValue = ValidUser.UserID AND FolderInfo.InfoCode = 4020
	LEFT OUTER JOIN tblSignatures ON FolderInfo.InfoValue = tblSignatures.UserID AND FolderInfo.InfoCode = 4020
	WHERE Folder.FolderRSN = @FolderRSN
	AND FolderPeople.PeopleCode = @PeopleRSN
END

GO
