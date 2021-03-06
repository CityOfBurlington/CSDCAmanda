USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[uspFULetter]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspFULetter](@FolderRSN INT,
	@CurrentProcessCode INT, @NextProcessCode INT,
	@PrimaryPeopleCode INT, @SecondaryPeopleCode INT,
	@FeeAmount MONEY) AS BEGIN

	SELECT TOP 1 Folder.FolderRSN, 
		dbo.udf_GetMHInspectionDate(@FolderRSN, @CurrentProcessCode) AS LastInspectionDate,
		dbo.udf_GetMHInspectionDate(@FolderRSN, @NextProcessCode) AS NextInspectionDate,
		Folder.FolderName, 
		Folder.IssueUser, ValidUser.UserName, ValidUser.UserPhone, ValidUser.EmailAddress,
		tblSignatures.SignatureBlob, 

		dbo.udf_GetFirstPeopleName(@PrimaryPeopleCode, @FolderRSN) AS PrimaryPeopleName,
		dbo.udf_GetFirstPeopleAddressLine1(@PrimaryPeopleCode, @FolderRSN) AS PrimaryPeopleAddr1,
		dbo.udf_GetFirstPeopleAddressLine2(@PrimaryPeopleCode, @FolderRSN) AS PrimaryPeopleAddr2,
		dbo.udf_GetFirstPeopleAddressLine3(@PrimaryPeopleCode, @FolderRSN) AS PrimaryPeopleAddr3,
		dbo.udf_GetFirstPeopleAddressLine4(@PrimaryPeopleCode, @FolderRSN) AS PrimaryPeopleAddr4,

		dbo.udf_GetFirstPeopleName(@SecondaryPeopleCode, @FolderRSN) AS SecondaryPeopleName,
		dbo.udf_GetFirstPeopleAddressLine1(@SecondaryPeopleCode, @FolderRSN) AS SecondaryPeopleAddr1,
		dbo.udf_GetFirstPeopleAddressLine2(@SecondaryPeopleCode, @FolderRSN) AS SecondaryPeopleAddr2,
		dbo.udf_GetFirstPeopleAddressLine3(@SecondaryPeopleCode, @FolderRSN) AS SecondaryPeopleAddr3,
		dbo.udf_GetFirstPeopleAddressLine4(@SecondaryPeopleCode, @FolderRSN) AS SecondaryPeopleAddr4,

		dbo.FormatDateTime(Folder.InDate, 'LONGDATE') AS IssueDate,
		@FeeAmount AS FeeAmount
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
	LEFT OUTER JOIN ValidUser ON Folder.IssueUser = ValidUser.UserId
	LEFT OUTER JOIN tblSignatures ON Folder.IssueUser = tblSignatures.UserID
	WHERE Folder.FolderRSN = @FolderRSN
END

GO
