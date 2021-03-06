USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_FUWordLetter]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_FUWordLetter](@FolderRSN INT,
	@CurrentProcessCode INT, @NextProcessCode INT,
	@PrimaryPeopleCode INT, @SecondaryPeopleCode INT,
	@FeeAmount MONEY) 
RETURNS @BVT TABLE (FolderRSN INT PRIMARY KEY, FolderName VARCHAR(100), IssueUser VARCHAR(100), UserName VARCHAR(100),
					UserPhone VARCHAR(100), EmailAddress VARCHAR(100), LastInspectionDate VARCHAR(100), NextInspectionDate VARCHAR(100),
					PrimaryPeopleName VARCHAR(50), PrimaryPeopleOrgName VARCHAR(50), PrimaryPeopleAddr1 VARCHAR(50), 
					PrimaryPeopleAddr2 VARCHAR(50), PrimaryPeopleAddr3 VARCHAR(50), PrimaryPeopleAddr4 VARCHAR(50), 
					SecondaryPeopleName VARCHAR(50), SecondaryPeopleOrgName VARCHAR(50), SecondaryPeopleAddr1 VARCHAR(50), 
					SecondaryPeopleAddr2 VARCHAR(50), SecondaryPeopleAddr3 VARCHAR(50), SecondaryPeopleAddr4 VARCHAR(50), 
					IssueDate DATE, FeeAmount MONEY
					)
AS BEGIN

INSERT @BVT
(FolderRSN, FolderName, IssueUser, UserName, UserPhone, EmailAddress, LastInspectionDate, NextInspectionDate,
					PrimaryPeopleName, PrimaryPeopleOrgName, PrimaryPeopleAddr1, PrimaryPeopleAddr2, PrimaryPeopleAddr3, 
					PrimaryPeopleAddr4, SecondaryPeopleName, SecondaryPeopleOrgName, SecondaryPeopleAddr1, SecondaryPeopleAddr2, 
					SecondaryPeopleAddr3, SecondaryPeopleAddr4, IssueDate, FeeAmount)

SELECT TOP 1 Folder.FolderRSN, Folder.FolderName, Folder.IssueUser, ValidUser.UserName, ValidUser.UserPhone, ValidUser.EmailAddress,
	dbo.FormatDateTime(dbo.udf_GetMHInspectionDate(@FolderRSN, @CurrentProcessCode), 'LONGDATEANDTIME') AS LastInspectionDate,
	dbo.FormatDateTime(dbo.udf_GetMHInspectionDate(@FolderRSN, @NextProcessCode), 'LONGDATEANDTIME') AS NextInspectionDate,
	dbo.MH_GetFirstFolderPeopleName(@FolderRSN, @PrimaryPeopleCode) AS PrimaryPeopleName,

		CASE WHEN dbo.MH_GetFirstFolderPeopleName(@FolderRSN, @PrimaryPeopleCode) <> dbo.MH_GetFirstFolderPeopleName(@FolderRSN, @PrimaryPeopleCode)
		THEN dbo.udf_GetFirstPeopleOrganizationName(@PrimaryPeopleCode, @FolderRSN)
		ELSE ''
		END AS PrimaryPeopleOrgName, 

	dbo.udf_GetFirstPeopleAddressLine1(@PrimaryPeopleCode, @FolderRSN) AS PrimaryPeopleAddr1,
	dbo.udf_GetFirstPeopleAddressLine2(@PrimaryPeopleCode, @FolderRSN) AS PrimaryPeopleAddr2,
	dbo.udf_GetFirstPeopleAddressLine3(@PrimaryPeopleCode, @FolderRSN) AS PrimaryPeopleAddr3,
	dbo.udf_GetFirstPeopleAddressLine4(@PrimaryPeopleCode, @FolderRSN) AS PrimaryPeopleAddr4,

		CASE WHEN dbo.udf_GetFirstPeopleTypeRSN(@PrimaryPeopleCode, @FolderRSN) = dbo.udf_GetFirstPeopleTypeRSN(@SecondaryPeopleCode, @FolderRSN) THEN ''
		ELSE dbo.udf_GetFirstPeopleName(@SecondaryPeopleCode, @FolderRSN) END AS SecondaryPeopleName,

		CASE WHEN dbo.MH_GetFirstFolderPeopleName(@FolderRSN, @PrimaryPeopleCode) <> dbo.MH_GetFirstFolderPeopleName(@FolderRSN, @SecondaryPeopleCode) THEN ''
		ELSE 
				CASE WHEN dbo.udf_GetFirstPeopleOrganizationName(@SecondaryPeopleCode, @FolderRSN) <> dbo.udf_GetFirstPeopleName(@SecondaryPeopleCode, @FolderRSN) 
				THEN dbo.MH_GetFirstFolderPeopleName(@FolderRSN, @SecondaryPeopleCode)
				ELSE ''
				END 
		END AS SecondaryPeopleOrgName, 


		CASE WHEN dbo.udf_GetFirstPeopleTypeRSN(@PrimaryPeopleCode, @FolderRSN) = dbo.udf_GetFirstPeopleTypeRSN(@SecondaryPeopleCode, @FolderRSN) THEN ''
		ELSE dbo.udf_GetFirstPeopleAddressLine1(@SecondaryPeopleCode, @FolderRSN) END AS SecondaryPeopleAddr1,

		CASE WHEN dbo.udf_GetFirstPeopleTypeRSN(@PrimaryPeopleCode, @FolderRSN) = dbo.udf_GetFirstPeopleTypeRSN(@SecondaryPeopleCode, @FolderRSN) THEN ''
		ELSE dbo.udf_GetFirstPeopleAddressLine2(@SecondaryPeopleCode, @FolderRSN) END AS SecondaryPeopleAddr2,

		CASE WHEN dbo.udf_GetFirstPeopleTypeRSN(@PrimaryPeopleCode, @FolderRSN) = dbo.udf_GetFirstPeopleTypeRSN(@SecondaryPeopleCode, @FolderRSN) THEN ''
		ELSE dbo.udf_GetFirstPeopleAddressLine3(@SecondaryPeopleCode, @FolderRSN) END AS SecondaryPeopleAddr3,

		CASE WHEN dbo.udf_GetFirstPeopleTypeRSN(@PrimaryPeopleCode, @FolderRSN) = dbo.udf_GetFirstPeopleTypeRSN(@SecondaryPeopleCode, @FolderRSN) THEN ''
		ELSE dbo.udf_GetFirstPeopleAddressLine4(@SecondaryPeopleCode, @FolderRSN) END AS SecondaryPeopleAddr4,

		dbo.FormatDateTime(Folder.InDate, 'LONGDATE') AS IssueDate,
		@FeeAmount AS FeeAmount

	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
	LEFT OUTER JOIN ValidUser ON Folder.IssueUser = ValidUser.UserId
	WHERE Folder.FolderRSN = @FolderRSN

RETURN;
END

GO
