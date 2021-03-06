USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp1stFULetter]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp1stFULetter](@FolderRSN INT) AS BEGIN

	SELECT TOP 1 Folder.FolderRSN, 
		dbo.udf_GetMHInspectionDate(@FolderRSN, 20034) AS LastInspectionDate,
		dbo.udf_GetMHInspectionDate(@FolderRSN, 20037) AS NextInspectionDate,
		Folder.FolderName, 
		Folder.IssueUser, ValidUser.UserName, ValidUser.UserPhone, ValidUser.EmailAddress,
		tblSignatures.SignatureBlob, 

		dbo.udf_GetFirstPeopleName(322, @FolderRSN) AS PrimaryPeopleName,
		dbo.udf_GetFirstPeopleAddressLine1(322, @FolderRSN) AS PrimaryPeopleAddr1,
		dbo.udf_GetFirstPeopleAddressLine2(322, @FolderRSN) AS PrimaryPeopleAddr2,
		dbo.udf_GetFirstPeopleAddressLine3(322, @FolderRSN) AS PrimaryPeopleAddr3,
		dbo.udf_GetFirstPeopleAddressLine4(322, @FolderRSN) AS PrimaryPeopleAddr4,

		dbo.udf_GetFirstPeopleName(75, @FolderRSN) AS SecondaryPeopleName,
		dbo.udf_GetFirstPeopleAddressLine1(75, @FolderRSN) AS SecondaryPeopleAddr1,
		dbo.udf_GetFirstPeopleAddressLine2(75, @FolderRSN) AS SecondaryPeopleAddr2,
		dbo.udf_GetFirstPeopleAddressLine3(75, @FolderRSN) AS SecondaryPeopleAddr3,
		dbo.udf_GetFirstPeopleAddressLine4(75, @FolderRSN) AS SecondaryPeopleAddr4,

		dbo.FormatDateTime(Folder.InDate, 'LONGDATE') AS IssueDate,
		0 AS FeeAmount
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
	LEFT OUTER JOIN ValidUser ON Folder.IssueUser = ValidUser.UserId
	LEFT OUTER JOIN tblSignatures ON Folder.IssueUser = tblSignatures.UserID
	WHERE Folder.FolderRSN = @FolderRSN
END


GO
