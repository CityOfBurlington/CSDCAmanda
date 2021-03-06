USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[uspLetterheadContact]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspLetterheadContact](@FolderRSN INT, @PeopleRSN INT) AS
BEGIN
	SELECT TOP 1 Folder.FolderRSN, dbo.udf_GetInspectionRequestLetterDays(Folder.FolderRSN) AS DaysToReply,
	Folder.FolderName, Folder.IssueUser, 
	ValidUser.UserName, ValidUser.UserPhone, ValidUser.EmailAddress,
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
	LEFT OUTER JOIN ValidUser ON Folder.IssueUser = ValidUser.UserId
	LEFT OUTER JOIN tblSignatures ON Folder.IssueUser = tblSignatures.UserID
	WHERE Folder.FolderRSN = @FolderRSN
	AND FolderPeople.PeopleCode = @PeopleRSN
END
GO
